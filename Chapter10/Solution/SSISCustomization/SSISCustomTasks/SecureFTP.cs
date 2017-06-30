using System;
using Microsoft.SqlServer.Dts.Runtime;
using WinSCP;

namespace SSIS2016Cookbook
{
    public class SecureFTP : Task
    {
        private const String TASK_NAME = "Secure FTP Task";
        private const String FtpProtocolName_MISSING_MESAGE = "FtpProtocolName has not been set.";
        private const String FtpHostName_MISSING_MESAGE = "FtpHostName has not been set.";
        private const String FtpUserName_MISSING_MESAGE = "FtpUserName has not been set.";
        private const String FtpPassword_MISSING_MESAGE = "FtpPassword has not been set.";
        private const String FtpSshHostKeyFingerprint_MISSING_MESAGE = "FtpSshHostKeyFingerprint has not been set.";
        private const String FtpOperationName_MISSING_MESAGE = "FtpOperationName has not been set.";
        private const String FtpLocalPath_MISSING_MESAGE = "FtpLocalPath has not been set.";
        private const String FtpRemotePath_MISSING_MESAGE = "FtpRemotePath has not been set.";
        private const String REMOVE_ENABLED_MESSAGE = "FtpRemove is set to TRUE, which means that the file is going to be removed from the source.";
        private const String SESSION_OPEN_MESSAGE = "Session opened succesfully.";
        private const String REMOTE_DIRECTORY_MISSING_MESSAGE_PATTERN = "The specified remote [{0}] directory is missing.\r\nIt will be created.";
        private const String REMOTE_DIRECTORY_CREATED_MESSAGE_PATTERN = "The specified remote [{0}] directory has been created.";
        private const String REMOTE_FILES_MISSING_MESSAGE_PATTERN = "The specified remote file(s) [{0}] cannot be found.";
        private const String EXCEPTION_MESSAGE_PATTERN = "An error has occurred:\r\n\r\n{0}";
        private const String UNKNOWN_EXCEPTION_MESSAGE = "(No other information available.)";

        public String FtpProtocolName { get; set; }
        public String FtpHostName { get; set; }
        public Int32 FtpPortNumber { get; set; }
        public String FtpUserName { get; set; }
        public String FtpPassword { get; set; }
        public String FtpSshHostKeyFingerprint { get; set; }
        public String FtpOperationName { get; set; }
        public String FtpLocalPath { get; set; }
        public String FtpRemotePath { get; set; }
        public Boolean FtpRemove { get; set; }

        public override DTSExecResult Validate(Connections connections, VariableDispenser variableDispenser, IDTSComponentEvents componentEvents, IDTSLogging log)
        {
            Boolean fireAgain = false;

            try
            {
                // Validate mandatory String properties.
                DTSExecResult propertyValidationResult = this.ValidateProperties(ref componentEvents);
                if (propertyValidationResult != DTSExecResult.Success)
                {
                    return propertyValidationResult;
                }

                // The package developer should know that files will be removed from the source.
                if (this.FtpRemove)
                {
                    componentEvents.FireInformation(0, TASK_NAME, REMOVE_ENABLED_MESSAGE, String.Empty, 0, ref fireAgain);
                }

                // Verify the connection.
                using (Session winScpSession = this.EstablishSession())
                {
                    componentEvents.FireInformation(0, TASK_NAME, SESSION_OPEN_MESSAGE, String.Empty, 0, ref fireAgain);

                    // Verify the remote resources.
                    OperationMode operation = (OperationMode)Enum.Parse(typeof(OperationMode), this.FtpOperationName);
                    switch (operation)
                    {
                        case OperationMode.PutFiles:
                            Boolean remoteDirectoryExists = winScpSession.FileExists(this.FtpRemotePath);
                            if (!remoteDirectoryExists)
                            {
                                componentEvents.FireInformation(0, TASK_NAME, String.Format(REMOTE_DIRECTORY_MISSING_MESSAGE_PATTERN, this.FtpRemotePath), String.Empty, 0, ref fireAgain);
                            }
                            break;
                        case OperationMode.GetFiles:
                        default:
                            Boolean remoteFileExists = winScpSession.FileExists(this.FtpRemotePath);
                            if (!remoteFileExists)
                            {
                                componentEvents.FireInformation(0, TASK_NAME, String.Format(REMOTE_FILES_MISSING_MESSAGE_PATTERN, this.FtpRemotePath), String.Empty, 0, ref fireAgain);
                            }
                            break;
                    }
                }

                return DTSExecResult.Success;
            }
            catch (Exception exc)
            {
                String exceptionMessage = exc != null ? exc.Message : UNKNOWN_EXCEPTION_MESSAGE;
                componentEvents.FireError(0, TASK_NAME, String.Format(EXCEPTION_MESSAGE_PATTERN, exceptionMessage), String.Empty, 0);
                return DTSExecResult.Failure;
            }
        }

        public override DTSExecResult Execute(Connections connections, VariableDispenser variableDispenser, IDTSComponentEvents componentEvents, IDTSLogging log, object transaction)
        {
            Boolean fireAgain = false;

            try
            {
                // Create a new FTP session.
                using (Session winScpSession = this.EstablishSession())
                {
                    componentEvents.FireInformation(0, TASK_NAME, SESSION_OPEN_MESSAGE, String.Empty, 0, ref fireAgain);

                    // Determine the operation mode.
                    OperationMode operation = (OperationMode)Enum.Parse(typeof(OperationMode), this.FtpOperationName);
                    switch (operation)
                    {
                        case OperationMode.PutFiles:
                            // When uploading files, make sure that the destination directory exists.
                            Boolean remoteDirectoryExists = winScpSession.FileExists(this.FtpRemotePath);
                            if (!remoteDirectoryExists)
                            {
                                winScpSession.CreateDirectory(this.FtpRemotePath);
                                componentEvents.FireInformation(0, TASK_NAME, String.Format(REMOTE_DIRECTORY_CREATED_MESSAGE_PATTERN, this.FtpRemotePath), String.Empty, 0, ref fireAgain);
                            }
                            winScpSession.PutFiles(this.FtpLocalPath, this.FtpRemotePath, this.FtpRemove);
                            break;
                        case OperationMode.GetFiles:
                        default:
                            winScpSession.GetFiles(this.FtpRemotePath, this.FtpLocalPath, this.FtpRemove);
                            break;
                    }

                    return DTSExecResult.Success;
                }
            }
            catch (Exception exc)
            {
                String exceptionMessage = exc == null ? UNKNOWN_EXCEPTION_MESSAGE : exc.Message;
                componentEvents.FireError(0, TASK_NAME, String.Format(EXCEPTION_MESSAGE_PATTERN, exceptionMessage), String.Empty, 0);
                return DTSExecResult.Failure;
            }
        }

        private Session EstablishSession()
        {
            Session winScpSession = new Session();

            Protocol ftpProtocol = (Protocol)Enum.Parse(typeof(Protocol), this.FtpProtocolName);

            SessionOptions winScpSessionOptions = new SessionOptions
            {
                Protocol = ftpProtocol,
                HostName = this.FtpHostName,
                PortNumber = this.FtpPortNumber,
                UserName = this.FtpUserName,
                Password = this.FtpPassword,
                SshHostKeyFingerprint = this.FtpSshHostKeyFingerprint
            };

            winScpSession.Open(winScpSessionOptions);

            return winScpSession;
        }

        private DTSExecResult ValidateProperties(ref IDTSComponentEvents componentEvents)
        {
            DTSExecResult result = DTSExecResult.Success;

            if (String.IsNullOrEmpty(this.FtpProtocolName))
            {
                componentEvents.FireError(0, TASK_NAME, FtpProtocolName_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpHostName))
            {
                componentEvents.FireError(0, TASK_NAME, FtpHostName_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpUserName))
            {
                componentEvents.FireError(0, TASK_NAME, FtpUserName_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpPassword))
            {
                componentEvents.FireError(0, TASK_NAME, FtpPassword_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpSshHostKeyFingerprint))
            {
                componentEvents.FireError(0, TASK_NAME, FtpSshHostKeyFingerprint_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpOperationName))
            {
                componentEvents.FireError(0, TASK_NAME, FtpOperationName_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpLocalPath))
            {
                componentEvents.FireError(0, TASK_NAME, FtpLocalPath_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            if (String.IsNullOrEmpty(this.FtpRemotePath))
            {
                componentEvents.FireError(0, TASK_NAME, FtpRemotePath_MISSING_MESAGE, String.Empty, 0);
                result = DTSExecResult.Failure;
            }

            return result;
        }

        public enum OperationMode
        {
            GetFiles,
            PutFiles
        }
    }
}
