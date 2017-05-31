using System;
namespace PoshLTM
{
    public struct F5Address
    {
        public static PoshLTM.F5Address Any = System.Net.IPAddress.Any;
        public string ComputerName;
        public System.Net.IPAddress IPAddress;
        public int? RouteDomain;

        public F5Address(string address)
        {
            ComputerName = "";
            // TODO: Implement ComputerName%RouteDomain syntax?
            if (System.Text.RegularExpressions.Regex.IsMatch(address,"%[0-9]+$"))
            {
                IPAddress = System.Net.IPAddress.Parse(address.Split('%')[0]);
                RouteDomain = int.Parse(address.Split('%')[1]);
            }
            else
            {
                // IPv4 Addresses always start with a number, server names can not
                if (System.Text.RegularExpressions.Regex.IsMatch(address,"^[0-9]"))
                {
                    IPAddress = System.Net.IPAddress.Parse(address);
                }
                else
                {
                    // IPv6 Addresses do not always start with a number, but resolve nicely
                    // TODO: Is GetHostAddresses[0] sufficient, or should we favor IPv4 addresses?
                    IPAddress = System.Net.Dns.GetHostAddresses(address)[0];
                    // If IPv4 the input string wasn't IPv6 so save the input as ComputerName for reference
                    if (IPAddress.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork) {
                        ComputerName = address;
                    }
                }
                RouteDomain = null;
            }
        }

        #region Override Equals

        // https://msdn.microsoft.com/ru-ru/library/ms173147(v=vs.80).aspx
        public override bool Equals(System.Object obj)
        {
            // If parameter is null return false.
            if (obj == null)
            {
                return false;
            }
            if (obj is PoshLTM.F5Address)
            {
                return this.Equals((PoshLTM.F5Address)obj);
            }
            if (obj is System.Net.IPAddress)
            {
                return this.IPAddress.Equals((System.Net.IPAddress)obj);
            }
            if (obj is string)
            {
                return this.ToString().Equals((string)obj);
            }
            return false;
        }

        public bool Equals(PoshLTM.F5Address other)
        {
            return IPAddress.Equals(other.IPAddress) && RouteDomain.Equals(other.RouteDomain) && ComputerName.Equals(ComputerName);
        }

        // Required to override Equals
        public override int GetHashCode()
        {
            return this.ToString().GetHashCode();
        }

        #endregion

        // This differs from Equals: it will match on IP alone if no RouteDomain criteria is specified.
        public bool IsMatch(string address)
        {
            // Built-in matching for the default (Any) filter
            if (this.Equals(Any)) {
                return true;
            }
            if (RouteDomain.HasValue)
            {
                return this.ToString() == address;
            }
            else
            {
                PoshLTM.F5Address f5address = new PoshLTM.F5Address(address);
                return IPAddress.ToString() == f5address.IPAddress.ToString();
            }
        }

        public override string ToString()
        {
            return String.Format("{0}{1:\\%0}", IPAddress, RouteDomain);
        }

        public static implicit operator PoshLTM.F5Address(System.Net.IPAddress value)
        {
            return new PoshLTM.F5Address(value.ToString());
        }
        public static implicit operator PoshLTM.F5Address(string value)
        {
            return new PoshLTM.F5Address(value);
        }
        public static implicit operator System.Net.IPAddress(PoshLTM.F5Address value)
        {
            return value.IPAddress;
        }
        public static implicit operator string(PoshLTM.F5Address value)
        {
            return String.Format("{0}{1:\\%0}", value.IPAddress, value.RouteDomain);
        }
        public static bool IsMatch(PoshLTM.F5Address filter, string address)
        {
            return filter.IsMatch(address);
        }
        public static bool IsMatch(PoshLTM.F5Address[] filter, string address)
        {
            foreach(PoshLTM.F5Address f in filter)
            {
                if (f.IsMatch(address))
                {
                    return true;
                }
            }
            return false;
        }
    }
}