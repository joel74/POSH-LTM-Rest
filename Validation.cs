using System.Collections.Generic;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class SSLValidator
{
    private static Stack<RemoteCertificateValidationCallback> funcs = new Stack<RemoteCertificateValidationCallback>();

    private static bool OnValidateCertificate(object sender, X509Certificate certificate, X509Chain chain,
                                                SslPolicyErrors sslPolicyErrors)
    {
        return true;
    }

    public static void OverrideValidation()
    {
        funcs.Push(ServicePointManager.ServerCertificateValidationCallback);
        ServicePointManager.ServerCertificateValidationCallback =
            OnValidateCertificate;
    }

    public static void RestoreValidation()
    {
        if (funcs.Count > 0) {
            ServicePointManager.ServerCertificateValidationCallback = funcs.Pop();
        }
    }
}