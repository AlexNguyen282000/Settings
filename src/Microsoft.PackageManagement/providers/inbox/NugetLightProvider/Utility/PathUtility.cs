﻿
namespace Microsoft.PackageManagement.NuGetProvider 
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel;
    using System.IO;
    using System.Linq;
    using System.Net;
    using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Runtime.InteropServices;

    internal static class PathUtility
    {
        private static readonly char[] _invalidPathChars = Path.GetInvalidPathChars();

        internal static string EnsureTrailingSlash(string path)
        {
            //The value of DirectorySeparatorChar is a slash ("/") on UNIX, and a backslash ("\") on the Windows and Macintosh.
            return EnsureTrailingCharacter(path, Path.DirectorySeparatorChar);
        }

        private static string EnsureTrailingCharacter(string path, char trailingCharacter)
        {
            if (path == null)
            {
                throw new ArgumentNullException("path");
            }

            // if the path is empty, we want to return the original string instead of a single trailing character.
            if (path.Length == 0 || path[path.Length - 1] == trailingCharacter)
            {
                return path;
            }
           
            return path + trailingCharacter;
        }

        internal static bool IsManifest(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return false;
            }

            return Path.GetExtension(path).Equals(NuGetConstant.ManifestExtension, StringComparison.OrdinalIgnoreCase);
        }

        internal static bool IsPackageFile(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return false;
            }

            return Path.GetExtension(path).Equals(NuGetConstant.PackageExtension, StringComparison.OrdinalIgnoreCase);
        }

        internal static bool ValidateSourceUri(IEnumerable<string> supportedSchemes, Uri srcUri, NuGetRequest request)
        {

            if (!supportedSchemes.Contains(srcUri.Scheme.ToLowerInvariant()))
            {
                return false;
            }

            if (srcUri.IsFile)
            {              
                //validate file source location
                if (Directory.Exists(srcUri.LocalPath))
                {
                    return true;
                }
                return false;
            }

            //validate uri source location
            return ValidateUri(srcUri, request) != null;
        }

        internal static HttpResponseMessage GetHttpResponse(HttpClient httpClient, string query, Request request)
        {
            // try downloading for 3 times
            int remainingTry = 3;
            object timerLock = new object();
            Timer timer = null;
            CancellationTokenSource cts = null;
            bool cleanUp = true;

            Action cleanUpAction = () =>
            {
                lock (timerLock)
                {
                    // check whether clean up is already done before or not
                    if (!cleanUp)
                    {
                        try
                        {
                            if (timer != null)
                            {
                                // stop timer
                                timer.Change(Timeout.Infinite, Timeout.Infinite);
                                // dispose it
                                timer.Dispose();
                            }

                            // dispose the token
                            if (cts != null)
                            {
                                cts.Cancel();
                                cts.Dispose();
                            }
                        }
                        catch { }

                        cleanUp = true;
                    }
                }
            };

            while (remainingTry > 0)
            {
                // if user cancel the request, no need to do anything
                if (request.IsCanceled)
                {
                    break;
                }

                try
                {
                    // decrease try by 1
                    remainingTry -= 1;

                    // create new timer and cancellation token source
                    lock (timerLock)
                    {
                        // check every second to see whether request is cancelled
                        timer = new Timer(_ =>
                        {
                            if (request.IsCanceled)
                            {
                                cleanUpAction();
                            }
                        }, null, 500, 1000);

                        cts = new CancellationTokenSource();

                        cleanUp = false;
                    }

                    Task task = httpClient.GetAsync(query, cts.Token);

                    // start the task
                    task.Wait();

                    if (task.IsCompleted && task is Task<HttpResponseMessage>)
                    {
                        var result = (task as Task<HttpResponseMessage>).Result;

                        // if success, returns result
                        if (result.IsSuccessStatusCode)
                        {
                            return result;
                        }

                        // otherwise, we have to retry again
                    }

                    // if request is canceled, don't retry
                    if (request.IsCanceled)
                    {
                        break;
                    }

                    request.Verbose(Resources.Messages.RetryingDownload, query, remainingTry);
                }
                catch (Exception ex)
                {
                    if (ex is AggregateException)
                    {
                        (ex as AggregateException).Handle(singleException =>
                            {
                                // report each of the exception
                                request.Verbose(singleException.Message);
                                request.Debug(singleException.StackTrace);
                                return true;
                            });
                    }
                    else
                    {
                        // single exception, just report the message and stacktrace
                        request.Verbose(ex.Message);
                        request.Debug(ex.StackTrace);
                    }

                    // if there is exception, we will retry too
                    request.Verbose(Resources.Messages.RetryingDownload, query, remainingTry);
                }
                finally
                {
                    cleanUpAction();
                }
            }

            return null;
        }

        /// <summary>
        /// Returns the validated uri. Returns null if we cannot validate it
        /// </summary>
        /// <param name="query"></param>
        /// <param name="request"></param>
        /// <returns></returns>
        internal static Uri ValidateUri(Uri query, NuGetRequest request)
        {
            var client = request.ClientWithoutAcceptHeader;

            var response = GetHttpResponse(client, query.AbsoluteUri, request);

            if (response == null)
            {
                return null;
            }

            // if response is not success, we need to check for redirection
            if (!response.IsSuccessStatusCode)
            {
                // Check for redirection (http status code 3xx)
                if (response.StatusCode == HttpStatusCode.MultipleChoices || response.StatusCode == HttpStatusCode.MovedPermanently
                    || response.StatusCode == HttpStatusCode.Found || response.StatusCode == HttpStatusCode.SeeOther
                    || response.StatusCode == HttpStatusCode.TemporaryRedirect)
                {
                    // get the redirected direction
                    string location = response.Headers.GetValues("Location").FirstOrDefault();
                    if (String.IsNullOrWhiteSpace(location))
                    {
                        return null;
                    }

                    // make a new query based on location
                    query = new Uri(location);
                }
                else
                {
                    // other status code is wrong
                    return null;
                }
            }
            else
            {
                query = new Uri(response.RequestMessage.RequestUri.AbsoluteUri);
            }

            //Making a query like: www.nuget.org/api/v2/FindPackagesById()?id='FoooBarr' to check the server available. 
            //'FoooBarr' is an any random package id
            string queryUri = "FoooBarr".MakeFindPackageByIdQuery(PathUtility.UriCombine(query.AbsoluteUri, NuGetConstant.FindPackagesById));

            response = GetHttpResponse(client, queryUri, request);

            // The link is not valid
            if (response == null || !response.IsSuccessStatusCode)
            {
                return null;
            }

            return query;
        }

        internal static string UriCombine(string query, string append)
        {
            if (String.IsNullOrWhiteSpace(query)) return append;
            if (String.IsNullOrWhiteSpace(append)) return query;

            return query.TrimEnd('/') + "/" + append.TrimStart('/');
        }

#region CryptProtectData
        //internal struct DATA_BLOB
        //{
        //    public int cbData;
        //    public IntPtr pbData;
        //}

        //internal static void CopyByteToBlob(ref DATA_BLOB blob, byte[] data)
        //{
        //    blob.pbData = Marshal.AllocHGlobal(data.Length);

        //    blob.cbData = data.Length;

        //    Marshal.Copy(data, 0, blob.pbData, data.Length);
        //}

        //internal const uint CRYPTPROTECT_UI_FORBIDDEN = 0x1;

        //[DllImport("crypt32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        //private static extern bool CryptUnprotectData(ref DATA_BLOB pDataIn, ref string ppszDataDescr, ref DATA_BLOB pOptionalEntropy,
        //    IntPtr pvReserved, IntPtr pPromptStruct, uint dwFlags, ref DATA_BLOB pDataOut);

        //[DllImport("crypt32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        //private static extern bool CryptProtectData(ref DATA_BLOB pDataIn, string szDataDescr, ref DATA_BLOB pOptionalEntropy,
        //    IntPtr pvReserved, IntPtr pPromptStruct, uint dwFlags, ref DATA_BLOB pDataOut);

        //public static byte[] CryptProtect(byte[] dataIn, byte[] optionalEntropy, bool encryptionOperation)
        //{
        //    DATA_BLOB dataInBlob = new DATA_BLOB();
        //    DATA_BLOB optionalEntropyBlob = new DATA_BLOB();
        //    DATA_BLOB resultBlob = new DATA_BLOB();
        //    string description = String.Empty;

        //    try
        //    {
        //        // copy the encrypted blob
        //        CopyByteToBlob(ref dataInBlob, dataIn);
        //        CopyByteToBlob(ref optionalEntropyBlob, optionalEntropy);

        //        // use local user
        //        uint flags = CRYPTPROTECT_UI_FORBIDDEN;

        //        bool success = false;

        //        // doing decryption
        //        if (!encryptionOperation)
        //        {
        //            // call win32 api
        //            success = CryptUnprotectData(ref dataInBlob, ref description, ref optionalEntropyBlob, IntPtr.Zero, IntPtr.Zero, flags, ref resultBlob);
        //        }
        //        else
        //        {
        //            // doing encryption
        //            success = CryptProtectData(ref dataInBlob, description, ref optionalEntropyBlob, IntPtr.Zero, IntPtr.Zero, flags, ref resultBlob);
        //        }

        //        if (!success)
        //        {
        //            throw new Win32Exception(Marshal.GetLastWin32Error());
        //        }

        //        byte[] unencryptedBytes = new byte[resultBlob.cbData];

        //        Marshal.Copy(resultBlob.pbData, unencryptedBytes, 0, resultBlob.cbData);

        //        return unencryptedBytes;
        //    }
        //    finally
        //    {
        //        // free memory
        //        if (dataInBlob.pbData != IntPtr.Zero)
        //        {
        //            Marshal.FreeHGlobal(dataInBlob.pbData);
        //        }

        //        if (optionalEntropyBlob.pbData != IntPtr.Zero)
        //        {
        //            Marshal.FreeHGlobal(optionalEntropyBlob.pbData);
        //        }

        //        if (resultBlob.pbData != IntPtr.Zero)
        //        {
        //            Marshal.FreeHGlobal(resultBlob.pbData);
        //        }
        //    }
        //}
#endregion
    }
}