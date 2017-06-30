using Microsoft.SqlServer.Dts.Pipeline;
using Microsoft.SqlServer.Dts.Pipeline.Wrapper;
using Microsoft.SqlServer.Dts.Runtime.Wrapper;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;

namespace SSIS2016Cookbook
{
    [DtsPipelineComponent
        (
        ComponentType = ComponentType.Transform,
        DisplayName = "Validate Email",
        Description = "Validates email addresses using the corresponding rule in a data profile file.",
        NoEditor = false
        )]
    public class ValidateEmail : PipelineComponent
    {
        private const String DATA_PROFILE_FILE_NAME_PROPERTY_NAME = "Data Profile File Name";
        private const String DATA_PROFILE_FILE_NAME_PROPERTY_DESCRIPTION = "Data profile file name (fully qualified).";
        private const String DATA_PROFILE_COLUMN_NAME_PROPERTY_NAME = "Data Profile Column Name";
        private const String DATA_PROFILE_COLUMN_NAME_PROPERTY_DESCRIPTION = "The name of the columns in the data profile.";
        private const String INPUT_NAME = "ValidateEmailInput";
        private const String INPUT_COLUMN_NAME = "Input Column Name";
        private const String INPUT_COLUMN_DESCRIPTION = "The name of the column to be validated.";
        private const String OUTPUT_NAME = "ValidateEmailOutput";
        private const String IS_VALID_COLUMN_NAME = "IsValidEmail";
        private const String IS_VALID_COLUMN_DESCRIPTION = "True, if the value of the selected column is a valid email address; otherwise, False.";
        private const String IS_INTERNAL_OBJECT_PROPERTY_NAME = "isInternal";

        private const String TOO_MANY_INPUTS_MESSAGE = "Only a single input is supported.";
        private const String TOO_MANY_OUTPUTS_MESSAGE = "Only a single output is supported.";
        private const String DEFAULT_OUTPUT_MUST_EXIST_MESSAGE = "The built-in synchronous output cannot be removed.";
        private const String USER_DEFINED_COLUMNS_NOT_SUPPORTED = "User-defined columns are not supported.";
        private const String DEFAULT_COLUMNS_MUST_EXIST = "Built-in output columns cannot be removed";
        private const String DATA_PROFILE_FILE_NOT_FOUND_MESSAGE_PATTERN = "The file [{0}] could not be located.";
        private const String DATA_PROFILE_FILE_FOUND_MESSAGE_PATTERN = "The file [{0}] exists.";
        private const String REGEX_PATTERNS_LOADED_MESSAGE_PATTERN = "{0} Regular Expression patterns loaded.";
        private const String DATA_PROFILE_COLUMN_NOT_FOUND_MESSAGE_PATTERN = "The file [{0}] does not contain a column named [{1}].";
        private const String REGEX_PATTERNS_NOT_FOUND_MESSAGE_PATTERN = "The file [{0}] does not contain any Regular Expressions patterns data for a column named [{1}].";
        private const String INPUT_COLUMN_NOT_SET_MESSAGE = "The input column has not been set.";
        private const String INPUT_COLUMN_NOT_FOUND_MESSAGE_PATTERN = "An input column named [{0}] cannot be found.";
        private const String INPUT_COLUMN_FOUND_MESSAGE_PATTERN = "The input column named [{0}] was found.";
        private const String INPUT_COLUMN_DATATYPE_NOT_SUPPORTED_MESSAGE_PATTERN = "The data type [{0}] of the selected input column [{1}] is not supported.\r\nPlease, use a column with a supported data type: DT_NTEXT, DT_TEXT, DT_STR, or DT_WSTR.";

        private const String DATA_PROFILE_NAMESPACE = "http://schemas.microsoft.com/sqlserver/2008/DataDebugger/";
        private const String DATA_PROFILE_NAMESPACE_ALIAS = "dp";

        private const String DATA_PROFILE_COLUMN_XPATH_PATTERN
            = "/dp:DataProfile/dp:DataProfileOutput/dp:Profiles" +
            "/dp:ColumnPatternProfile[dp:Column[@Name='{0}']]";

        private const String REGEX_ELEMENT_XPATH_PATTERN
            = DATA_PROFILE_COLUMN_XPATH_PATTERN +
            "/dp:TopRegexPatterns/dp:PatternDistributionItem/dp:RegexText/text()";

        private String _dataProfileFileName;
        private String _dataProfileColumnName;
        private String _emailAddressInputColumnName;
        private List<String> _regexPatterns = new List<String>();

        public override void ProvideComponentProperties()
        {
            base.ProvideComponentProperties();

            // Data Profile File Name
            IDTSCustomProperty100 dataProfileFileName = ComponentMetaData.CustomPropertyCollection.New();
            dataProfileFileName.Name = DATA_PROFILE_FILE_NAME_PROPERTY_NAME;
            dataProfileFileName.Description = DATA_PROFILE_FILE_NAME_PROPERTY_DESCRIPTION;
            dataProfileFileName.State = DTSPersistState.PS_PERSISTASCDATA;
            dataProfileFileName.TypeConverter = typeof(String).AssemblyQualifiedName;
            dataProfileFileName.Value = String.Empty;

            // Data Profile Column Name
            IDTSCustomProperty100 dataProfileColumnName = ComponentMetaData.CustomPropertyCollection.New();
            dataProfileColumnName.Name = DATA_PROFILE_COLUMN_NAME_PROPERTY_NAME;
            dataProfileColumnName.Description = DATA_PROFILE_COLUMN_NAME_PROPERTY_DESCRIPTION;
            dataProfileColumnName.State = DTSPersistState.PS_DEFAULT;
            dataProfileColumnName.TypeConverter = typeof(String).AssemblyQualifiedName;
            dataProfileColumnName.Value = String.Empty;

            // Input
            IDTSInput100 input = ComponentMetaData.InputCollection[0];
            input.Name = INPUT_NAME;
            // Input Column Name
            IDTSCustomProperty100 inputColumnName = input.CustomPropertyCollection.New();
            inputColumnName.Name = INPUT_COLUMN_NAME;
            inputColumnName.Description = INPUT_COLUMN_DESCRIPTION;
            inputColumnName.State = DTSPersistState.PS_DEFAULT;
            inputColumnName.TypeConverter = typeof(String).AssemblyQualifiedName;
            inputColumnName.Value = String.Empty;

            IDTSCustomProperty100 isInternal;
            // Synchronous Output
            IDTSOutput100 output = ComponentMetaData.OutputCollection[0];
            output.Name = OUTPUT_NAME;
            output.SynchronousInputID = ComponentMetaData.InputCollection[0].ID;
            isInternal = output.CustomPropertyCollection.New();
            isInternal.Name = IS_INTERNAL_OBJECT_PROPERTY_NAME;
            isInternal.State = DTSPersistState.PS_DEFAULT;
            isInternal.TypeConverter = typeof(Boolean).AssemblyQualifiedName;
            isInternal.Value = true;
            // Output column
            IDTSOutputColumn100 isVaildEmailColumn = output.OutputColumnCollection.New();
            isVaildEmailColumn.Name = IS_VALID_COLUMN_NAME;
            isVaildEmailColumn.Description = IS_VALID_COLUMN_DESCRIPTION;
            isVaildEmailColumn.SetDataTypeProperties(DataType.DT_BOOL, 0, 0, 0, 0);
            isInternal = isVaildEmailColumn.CustomPropertyCollection.New();
            isInternal.Name = IS_INTERNAL_OBJECT_PROPERTY_NAME;
            isInternal.State = DTSPersistState.PS_DEFAULT;
            isInternal.TypeConverter = typeof(Boolean).AssemblyQualifiedName;
            isInternal.Value = true;
        }

        public override IDTSInput100 InsertInput(DTSInsertPlacement insertPlacement, Int32 inputID)
        {
            // Only one input is supported.
            throw new NotSupportedException(TOO_MANY_INPUTS_MESSAGE);
        }

        public override IDTSOutput100 InsertOutput(DTSInsertPlacement insertPlacement, Int32 outputID)
        {
            // Only one output is supported.
            throw new NotSupportedException(TOO_MANY_OUTPUTS_MESSAGE);
        }

        public override IDTSOutputColumn100 InsertOutputColumnAt(Int32 outputID, Int32 outputColumnIndex, String name, String description)
        {
            // No additional Output Columns can be added.
            throw new NotSupportedException(USER_DEFINED_COLUMNS_NOT_SUPPORTED);
        }

        public override void DeleteOutput(Int32 outputID)
        {
            // The built-in output cannot be removed.
            Boolean isInternal = (Boolean)(ComponentMetaData.OutputCollection.GetObjectByID(outputID).CustomPropertyCollection[IS_INTERNAL_OBJECT_PROPERTY_NAME].Value);
            if (isInternal)
            {
                throw new InvalidOperationException(DEFAULT_OUTPUT_MUST_EXIST_MESSAGE);
            }
            else
            {
                base.DeleteOutput(outputID);
            }
        }

        public override void DeleteOutputColumn(Int32 outputID, Int32 outputColumnID)
        {
            // Built-in output columns cannot be removed.
            Boolean isInternal = (Boolean)(ComponentMetaData.OutputCollection.GetObjectByID(outputID).OutputColumnCollection.GetObjectByID(outputColumnID).CustomPropertyCollection[IS_INTERNAL_OBJECT_PROPERTY_NAME].Value);
            if (isInternal)
            {
                throw new InvalidOperationException(DEFAULT_COLUMNS_MUST_EXIST);
            }
            else
            {
                base.DeleteOutputColumn(outputID, outputColumnID);
            }
        }

        public override DTSValidationStatus Validate()
        {
            Boolean isCanceled = false;
            Boolean fireAgain = false;

            // Only one input is supported.
            if (ComponentMetaData.InputCollection.Count > 1)
            {
                ComponentMetaData.FireError(0, ComponentMetaData.Name, TOO_MANY_INPUTS_MESSAGE, String.Empty, 0, out isCanceled);
                return DTSValidationStatus.VS_ISCORRUPT;
            }

            // Only one output is supported.
            if (ComponentMetaData.OutputCollection.Count > 1)
            {
                ComponentMetaData.FireError(0, ComponentMetaData.Name, TOO_MANY_OUTPUTS_MESSAGE, String.Empty, 0, out isCanceled);
                return DTSValidationStatus.VS_ISCORRUPT;
            }

            this.ResolveComponentCustomProperties();

            // Data profile file must exist.
            if (!File.Exists(_dataProfileFileName))
            {
                ComponentMetaData.FireError(0, ComponentMetaData.Name, String.Format(DATA_PROFILE_FILE_NOT_FOUND_MESSAGE_PATTERN, _dataProfileFileName), String.Empty, 0, out isCanceled);
                return DTSValidationStatus.VS_ISBROKEN;
            }
            else
            {
                ComponentMetaData.FireInformation(0, ComponentMetaData.Name, String.Format(DATA_PROFILE_FILE_FOUND_MESSAGE_PATTERN, _dataProfileFileName), String.Empty, 0, ref fireAgain);

                // Data profile file must contain at least one Regular Expressions pattern for the specified column name.
                Int32 regexPatternCount = _regexPatterns.Count();
                if (regexPatternCount > 0)
                {
                    ComponentMetaData.FireInformation(0, ComponentMetaData.Name, String.Format(REGEX_PATTERNS_LOADED_MESSAGE_PATTERN, regexPatternCount), String.Empty, 0, ref fireAgain);
                }
                else
                {
                    if (!this.DataProfileColumnExists(_dataProfileFileName, _dataProfileColumnName))
                    {
                        ComponentMetaData.FireWarning(0, ComponentMetaData.Name, String.Format(DATA_PROFILE_COLUMN_NOT_FOUND_MESSAGE_PATTERN, _dataProfileFileName, _dataProfileColumnName), String.Empty, 0);
                        return DTSValidationStatus.VS_ISBROKEN;
                    }
                    else
                    {
                        ComponentMetaData.FireWarning(0, ComponentMetaData.Name, String.Format(REGEX_PATTERNS_NOT_FOUND_MESSAGE_PATTERN, _dataProfileFileName, _dataProfileColumnName), String.Empty, 0);
                        return DTSValidationStatus.VS_ISBROKEN;
                    }
                }
            }

            // The input column must exist and must be of a supported data type.
            if (String.IsNullOrEmpty(_emailAddressInputColumnName))
            {
                ComponentMetaData.FireError(0, ComponentMetaData.Name, INPUT_COLUMN_NOT_SET_MESSAGE, String.Empty, 0, out isCanceled);
                return DTSValidationStatus.VS_ISBROKEN;
            }
            else
            {
                IDTSInputColumn100 inputColumn = ComponentMetaData.InputCollection[INPUT_NAME].InputColumnCollection[_emailAddressInputColumnName];
                if (inputColumn == null)
                {
                    ComponentMetaData.FireError(0, ComponentMetaData.Name, String.Format(INPUT_COLUMN_NOT_FOUND_MESSAGE_PATTERN, inputColumn.Name), String.Empty, 0, out isCanceled);
                    return DTSValidationStatus.VS_ISBROKEN;
                }
                else
                {
                    ComponentMetaData.FireInformation(0, ComponentMetaData.Name, String.Format(INPUT_COLUMN_FOUND_MESSAGE_PATTERN, inputColumn.Name), String.Empty, 0, ref fireAgain);

                    if (inputColumn.DataType != DataType.DT_NTEXT &&
                        inputColumn.DataType != DataType.DT_TEXT &&
                        inputColumn.DataType != DataType.DT_STR &&
                        inputColumn.DataType != DataType.DT_WSTR)
                    {
                        ComponentMetaData.FireError(0, ComponentMetaData.Name, String.Format(INPUT_COLUMN_DATATYPE_NOT_SUPPORTED_MESSAGE_PATTERN, inputColumn.DataType.ToString(), inputColumn.Name), String.Empty, 0, out isCanceled);
                        return DTSValidationStatus.VS_ISBROKEN;
                    }
                }
            }

            return base.Validate();
        }

        public override void PreExecute()
        {
            base.PreExecute();

            this.ResolveComponentCustomProperties();
        }

        public override void ProcessInput(Int32 inputID, PipelineBuffer buffer)
        {
            IDTSInput100 input = ComponentMetaData.InputCollection.GetObjectByID(inputID);
            Int32 emailAddressInputColumnId = input.InputColumnCollection[_emailAddressInputColumnName].ID;
            IDTSInputColumn100 emailAddressInputColumn = input.InputColumnCollection.GetObjectByID(emailAddressInputColumnId);
            Int32 emailAddressInputColumnIndex = input.InputColumnCollection.GetObjectIndexByID(emailAddressInputColumnId);

            IDTSOutput100 output = ComponentMetaData.OutputCollection[OUTPUT_NAME];
            Int32 isValidColumnId = output.OutputColumnCollection[IS_VALID_COLUMN_NAME].ID;
            IDTSOutputColumn100 isValidColumn = output.OutputColumnCollection.GetObjectByID(isValidColumnId);
            Int32 isValidColumnIndex = BufferManager.FindColumnByLineageID(input.Buffer, isValidColumn.LineageID);

            while (buffer.NextRow())
            {
                String emailAddress;
                switch (emailAddressInputColumn.DataType)
                {
                    case DataType.DT_NTEXT:
                        emailAddress = Encoding.Unicode.GetString(buffer.GetBlobData(emailAddressInputColumnIndex, 0, (Int32)buffer.GetBlobLength(emailAddressInputColumnIndex)));
                        break;
                    case DataType.DT_TEXT:
                        emailAddress = Encoding.GetEncoding(emailAddressInputColumn.CodePage).GetString(buffer.GetBlobData(emailAddressInputColumnIndex, 0, emailAddressInputColumn.Length));
                        break;
                    default:
                        emailAddress = buffer.GetString(emailAddressInputColumnIndex);
                        break;
                }

                buffer.SetBoolean(isValidColumnIndex, this.IsValidEmail(emailAddress));
            }

            if (buffer.EndOfRowset)
            {
            }
        }

        public override void PostExecute()
        {
            _regexPatterns.Clear();

            base.PostExecute();
        }

        private Boolean DataProfileColumnExists(String dataProfileName, String columnName)
        {
            Boolean result = true;

            XmlDocument dataProfile = new XmlDocument();
            dataProfile.Load(dataProfileName);
            XmlNamespaceManager dataProfileNSM = new XmlNamespaceManager(dataProfile.NameTable);
            dataProfileNSM.AddNamespace(DATA_PROFILE_NAMESPACE_ALIAS, DATA_PROFILE_NAMESPACE);

            String regexElementXPath = String.Format(DATA_PROFILE_COLUMN_XPATH_PATTERN, columnName);
            XmlNode dataProfileColumn = dataProfile.SelectSingleNode(regexElementXPath, dataProfileNSM);
            if (dataProfileColumn == null)
            {
                result = false;
            }

            return result;
        }

        private List<String> LoadRegularExpressions(String dataProfileName, String columnName)
        {
            List<String> result = new List<String>();

            if (!String.IsNullOrEmpty(dataProfileName) &&
                !String.IsNullOrEmpty(columnName))
            {
                XmlDocument dataProfile = new XmlDocument();
                dataProfile.Load(dataProfileName);
                XmlNamespaceManager dataProfileNSM = new XmlNamespaceManager(dataProfile.NameTable);
                dataProfileNSM.AddNamespace(DATA_PROFILE_NAMESPACE_ALIAS, DATA_PROFILE_NAMESPACE);

                String regexElementXPath = String.Format(REGEX_ELEMENT_XPATH_PATTERN, columnName);
                foreach (XmlNode regexPatternElement in dataProfile.SelectNodes(regexElementXPath, dataProfileNSM))
                {
                    String regexPattern = regexPatternElement.Value;
                    if (!result.Contains(regexPattern))
                    {
                        result.Add(regexPattern);
                    }
                }
            }

            return result;
        }

        private Boolean IsValidEmail(String emailAddress)
        {
            Boolean result = false;

            if (!String.IsNullOrEmpty(emailAddress))
            {
                foreach (String regexPattern in _regexPatterns)
                {
                    if (Regex.IsMatch(emailAddress, regexPattern, RegexOptions.IgnoreCase))
                    {
                        result = true;
                        break;
                    }
                }
            }

            return result;
        }

        private void ResolveComponentCustomProperties()
        {
            _dataProfileFileName = ComponentMetaData.CustomPropertyCollection[DATA_PROFILE_FILE_NAME_PROPERTY_NAME].Value.ToString();
            if (VariableDispenser.Contains(_dataProfileFileName))
            {
                IDTSVariables100 variables = null;
                VariableDispenser.LockOneForRead(_dataProfileFileName, ref variables);
                _dataProfileFileName = (String)variables[0].Value;
            }

            _dataProfileColumnName = ComponentMetaData.CustomPropertyCollection[DATA_PROFILE_COLUMN_NAME_PROPERTY_NAME].Value.ToString();
            if (VariableDispenser.Contains(_dataProfileColumnName))
            {
                IDTSVariables100 variables = null;
                VariableDispenser.LockOneForRead(_dataProfileColumnName, ref variables);
                _dataProfileColumnName = (String)variables[0].Value;
            }

            _regexPatterns.Clear();
            _regexPatterns = this.LoadRegularExpressions(_dataProfileFileName, _dataProfileColumnName);

            _emailAddressInputColumnName = ComponentMetaData.InputCollection[INPUT_NAME].CustomPropertyCollection[INPUT_COLUMN_NAME].Value.ToString();
        }
    }
}
