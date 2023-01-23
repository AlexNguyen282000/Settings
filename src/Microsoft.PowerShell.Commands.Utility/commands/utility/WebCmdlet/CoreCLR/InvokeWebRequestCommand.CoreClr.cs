// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Net.Http;

namespace Microsoft.PowerShell.Commands
{
    /// <summary>
    /// The Invoke-WebRequest command.
    /// This command makes an HTTP or HTTPS request to a web server and returns the results.
    /// </summary>
    [Cmdlet(VerbsLifecycle.Invoke, "WebRequest", HelpUri = "https://go.microsoft.com/fwlink/?LinkID=2097126", DefaultParameterSetName = "StandardMethod")]
    [OutputType(typeof(BasicHtmlWebResponseObject))]
    public class InvokeWebRequestCommand : WebRequestPSCmdlet
    {
        #region Virtual Method Overrides

        /// <summary>
        /// Initializes a new instance of the <see cref="InvokeWebRequestCommand"/> class.
        /// </summary>
        public InvokeWebRequestCommand() : base()
        {
            this._parseRelLink = true;
        }

        /// <summary>
        /// Process the web response and output corresponding objects.
        /// </summary>
        /// <param name="response"></param>
        internal override void ProcessResponse(HttpResponseMessage response)
        {
            ArgumentNullException.ThrowIfNull(response);

            Stream responseStream = StreamHelper.GetResponseStream(response);
            if (ShouldWriteToPipeline)
            {
                // creating a MemoryStream wrapper to response stream here to support IsStopping.
                responseStream = new WebResponseContentMemoryStream(
                    responseStream,
                    StreamHelper.ChunkSize,
                    this,
                    response.Content.Headers.ContentLength.GetValueOrDefault());
                WebResponseObject ro = WebResponseObjectFactory.GetResponseObject(response, responseStream, this.Context);
                ro.RelationLink = _relationLink;
                WriteObject(ro);

                // use the rawcontent stream from WebResponseObject for further
                // processing of the stream. This is need because WebResponse's
                // stream can be used only once.
                responseStream = ro.RawContentStream;
                responseStream.Seek(0, SeekOrigin.Begin);
            }

            if (ShouldSaveToOutFile)
            {
                // Check if OutFile is a folder
                if (Directory.Exists(OutFile))
                {
                    if (response.Headers.TryGetValues(HttpKnownHeaderNames.ContentDisposition, out IEnumerable<string> contentDisposition)) 
                    {
                        IEnumerator<string> enumerator = contentDisposition.GetEnumerator();
                        if (enumerator.MoveNext())
                        {
                            // Get file name from Content-Disposition header if present
                            OutFile = Path.Combine(OutFile, Path.GetFileName((string)enumerator.Current));
                        }
                    }
                    else
                    {
                        // Get file name from last segment of Uri
                        OutFile = Path.Combine(OutFile, System.Net.WebUtility.UrlDecode(response.RequestMessage.RequestUri.Segments[^1]));
                    }
                }

                StreamHelper.SaveStreamToFile(responseStream, QualifiedOutFile, this, response.Content.Headers.ContentLength.GetValueOrDefault(), _cancelToken.Token);
            }
        }

        #endregion Virtual Method Overrides
    }
}
