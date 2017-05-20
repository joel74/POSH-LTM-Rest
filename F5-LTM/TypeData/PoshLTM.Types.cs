using System;
namespace PoshLTM
{
    public struct F5Address
    {
        public string ComputerName;
        public System.Net.IPAddress IPAddress;
        public int? RouteDomain;

        public F5Address(string address) {
            ComputerName = "";
            if (System.Text.RegularExpressions.Regex.IsMatch(address,"%[0-9]+$")) {
                IPAddress = System.Net.IPAddress.Parse(address.Split('%')[0]);
                RouteDomain = int.Parse(address.Split('%')[1]);
            } else {
                // IP Addresses always start with a number, server names can not
                if (System.Text.RegularExpressions.Regex.IsMatch(address,"^[0-9]")) {
                    IPAddress = System.Net.IPAddress.Parse(address);
                } else {
                    ComputerName = address;
                    IPAddress = System.Net.Dns.GetHostAddresses(ComputerName)[0];
                }
                RouteDomain = null;
            }
        }

        public override string ToString()
        {
            return String.Format("{0}{1:\\%0}", IPAddress, RouteDomain);
        }

        public static implicit operator F5Address(System.Net.IPAddress value)
        {
            return new PoshLTM.F5Address(value.ToString());
        }
        public static implicit operator F5Address(string value)
        {
            return new PoshLTM.F5Address(value);
        }
        public static implicit operator System.Net.IPAddress(F5Address value)
        {
            return value.IPAddress;
        }
        public static implicit operator string(F5Address value)
        {
            return String.Format("{0}{1:\\%0}", value.IPAddress, value.RouteDomain);
        }
    }
}
