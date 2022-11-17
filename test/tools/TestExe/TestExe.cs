// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;
using System.Threading;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace TestExe
{
    internal class TestExe
    {
        private static int Main(string[] args)
        {
            if (args.Length > 0)
            {
                switch (args[0].ToLowerInvariant())
                {
                    case "-echoargs":
                        EchoArgs(args);
                        break;
                    case "-echoraw":
                        EchoRaw(args);
                        break;
                    case "-createchildprocess":
                        CreateChildProcess(args);
                        break;
                    case "-returncode":
                        // Used to test functionality depending on $LASTEXITCODE, like &&/|| operators
                        Console.WriteLine(args[1]);
                        return int.Parse(args[1]);
                    case "-stderr":
                        Console.Error.WriteLine(args[1]);
                        break;
                    case "--help":
                    case "-h":
                        PrintHelp();
                        break;
                    default:
                        Console.WriteLine("Unknown test {0}", args[0]);
                        break;
                }
            }
            else
            {
                Console.WriteLine("Test not specified");
            }

            return 0;
        }

        // <Summary>
        // Echos back to stdout the arguments passed in
        // </Summary>
        private static void EchoArgs(string[] args)
        {
            for (int i = 1; i < args.Length; i++)
            {
                Console.WriteLine("Arg {0} is <{1}>", i - 1, args[i]);
            }
        }

        [DllImport("Kernel32.dll")]
        private static extern IntPtr GetCommandLineW();

        // <Summary>
        // Echos the raw command line received by the process plus the arguments passed in.
        // </Summary>
        private static void EchoRaw(string[] args)
        {
            string rawCmdLine = Environment.CommandLine;

            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                IntPtr cmdLinePtr = GetCommandLineW();
                rawCmdLine = Marshal.PtrToStringUni(cmdLinePtr);
            }

            Console.WriteLine("Raw Command Line:\n{0}\n", rawCmdLine);
            EchoArgs(args);
        }

        // <Summary>
        // Print help content.
        // </Summary>
        private static void PrintHelp()
        {
            const string content = @"
Options for echoing args are:
   -echoargs     Echos back to stdout the arguments passed in.
   -echoraw      Echos the raw command line received by the process plus the arguments passed in.

Other options are for specific tests only. Read source code for details.
";
            Console.WriteLine(content);
        }

        // <Summary>
        // First argument is the number of child processes to create which are instances of itself
        // Processes automatically exit after 100 seconds
        // </Summary>
        private static void CreateChildProcess(string[] args)
        {
            if (args.Length > 1)
            {
                uint num = UInt32.Parse(args[1]);
                for (uint i = 0; i < num; i++)
                {
                    Process child = new Process();
                    child.StartInfo.FileName = Environment.ProcessPath;
                    child.StartInfo.Arguments = "-createchildprocess";
                    child.Start();
                }
            }
            // sleep is needed so the process doesn't exit before the test case kill it
            Thread.Sleep(100000);
        }
    }
}
