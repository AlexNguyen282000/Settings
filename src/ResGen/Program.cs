// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Xml.Linq;

namespace ConsoleApplication
{
    public class Program
    {
        public static void Main(string[] args)
        {
            IEnumerable<string> dirs;
            string fileFilter;

            if (args.Length == 1)
            {
                // We are assuming resgen is run with 'dotnet run pathToResxFile.resx'.
                fileFilter = Path.GetFileName(args[0]);
                string moduleDirectory = Path.GetDirectoryName(Path.GetDirectoryName(args[0]));
                dirs = new List<string>() { moduleDirectory };
            }
            else
            {
                // We are assuming resgen is run with 'dotnet run'
                // so we can use relative path to get a parent directory
                // to process all *.resx files in all project subdirectories.
                fileFilter = "*.resx";
                dirs = Directory.EnumerateDirectories("..");
            }

            foreach (string folder in dirs)
            {
                string moduleName = Path.GetFileName(folder);
                string resourcePath = Path.Combine(folder, "resources");

                if (Directory.Exists(resourcePath))
                {
                    string genFolder = Path.Combine(folder, "gen");
                    if (!Directory.Exists(genFolder))
                    {
                        Directory.CreateDirectory(genFolder);
                    }

                    foreach (string resxPath in Directory.EnumerateFiles(resourcePath, fileFilter))
                    {
                        string className = Path.GetFileNameWithoutExtension(resxPath);
                        string sourceCode = GetStronglyTypeCsFileForResx(resxPath, moduleName, className);
                        string outPath = Path.Combine(genFolder, className + ".cs");
                        Console.WriteLine("ResGen for " + outPath);
                        File.WriteAllText(outPath, sourceCode);
                    }
                }
            }
        }

        private static string GetStronglyTypeCsFileForResx(string xmlPath, string moduleName, string className)
        {
            // Example
            //
            // className = Full.Name.Of.The.ClassFoo
            // shortClassName = ClassFoo
            // namespaceName = Full.Name.Of.The

            string shortClassName = className;
            string namespaceName = null;
            int lastIndexOfDot = className.LastIndexOf('.');
            if (lastIndexOfDot != -1)
            {
                namespaceName = className.Substring(0, lastIndexOfDot);
                shortClassName = className.Substring(lastIndexOfDot + 1);
            }

            var entries = new StringBuilder();
            XElement root = XElement.Parse(File.ReadAllText(xmlPath));
            foreach (var data in root.Elements("data"))
            {
                string value = data.Value.Replace("\n", "\n    ///");
                string name = data.Attribute("name").Value.Replace(' ', '_');
                entries.AppendFormat(ENTRY, name, value);
            }

            string bodyCode = string.Format(BODY, shortClassName, moduleName, entries.ToString(), className);
            if (namespaceName != null)
            {
                bodyCode = string.Format(NAMESPACE, namespaceName, bodyCode);
            }

            string resultCode = string.Format(BANNER, bodyCode).Replace("\r\n?|\n", "\r\n");
            return resultCode;
        }

        private static readonly string BANNER = @"
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a dotnet run from src\ResGen folder.
//     To add or remove a member, edit your .resx file then rerun src\ResGen.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

{0}
";

        private static readonly string NAMESPACE = @"
namespace {0} {{
{1}
}}
";
        private static readonly string BODY = @"
using System;
using System.Reflection;

/// <summary>
///   A strongly-typed resource class, for looking up localized strings, etc.
/// </summary>
[global::System.CodeDom.Compiler.GeneratedCodeAttribute(""System.Resources.Tools.StronglyTypedResourceBuilder"", ""4.0.0.0"")]
[global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
[global::System.Runtime.CompilerServices.CompilerGeneratedAttribute()]

internal class {0} {{

    private static global::System.Resources.ResourceManager resourceMan;

    private static global::System.Globalization.CultureInfo resourceCulture;

    [global::System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(""Microsoft.Performance"", ""CA1811:AvoidUncalledPrivateCode"")]
    internal {0}() {{
    }}

    /// <summary>
    ///   Returns the cached ResourceManager instance used by this class.
    /// </summary>
    [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
    internal static global::System.Resources.ResourceManager ResourceManager {{
        get {{
            if (object.ReferenceEquals(resourceMan, null)) {{
                global::System.Resources.ResourceManager temp = new global::System.Resources.ResourceManager(""{1}.resources.{3}"", typeof({0}).Assembly);
                resourceMan = temp;
            }}
            return resourceMan;
        }}
    }}

    /// <summary>
    ///   Overrides the current threads CurrentUICulture property for all
    ///   resource lookups using this strongly typed resource class.
    /// </summary>
    [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
    internal static global::System.Globalization.CultureInfo Culture {{
        get {{
            return resourceCulture;
        }}
        set {{
            resourceCulture = value;
        }}
    }}
    {2}
}}
";

    private static readonly string ENTRY = @"

    /// <summary>
    ///   Looks up a localized string similar to {1}
    /// </summary>
    internal static string {0} {{
        get {{
            return ResourceManager.GetString(""{0}"", resourceCulture);
        }}
    }}
";

    }
}
