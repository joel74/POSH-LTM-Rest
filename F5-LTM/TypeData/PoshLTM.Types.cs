using System;
using System.Net;
using System.Net.Sockets;
using System.Text.RegularExpressions;
namespace PoshLTM
{
    public struct F5Address
    {
        public static F5Address Any = IPAddress.Any;
        public IPAddress IPAddress;
        public int? RouteDomain;

        public F5Address(string address)
        {
            RouteDomain = null;
            IPAddress = null;
            string hostname = address;
            // Extract a RouteDomain, if applicable
            if (Regex.IsMatch(address,"%[0-9]+$"))
            {
                hostname = address.Split('%')[0];
                RouteDomain = int.Parse(address.Split('%')[1]);
            }
            // IPv4 Addresses always start with a number, server names can not
            if (Regex.IsMatch(hostname,"^[0-9]"))
            {
                IPAddress = IPAddress.Parse(hostname);
            }
            else if (address == "any6")
            {
                IPAddress = IPAddress.Any;
            }
            else
            {
                // Resolve hostname
                // IPv6 Addresses do not always start with a number, but resolve nicely
                foreach (IPAddress IPA in Dns.GetHostAddresses(hostname))
                {
                    // This avoids (but does not prevent) getting no address at all
                    IPAddress = IPA;
                    // This applies a bias in favor of IPv4 or IPv6 addresses that are NOT LinkLocal which often have a physical NIC ScopeId, not to be confused with a RouteDomain
                    if (IPA.AddressFamily == AddressFamily.InterNetwork || (IPA.AddressFamily == AddressFamily.InterNetworkV6 && !IPA.IsIPv6LinkLocal))
                    {
                        break;
                    }
                }
            }
        }

        #region Override Equals

        // https://msdn.microsoft.com/ru-ru/library/ms173147(v=vs.80).aspx
        public override bool Equals(Object obj)
        {
            // If parameter is null return false.
            if (obj == null)
            {
                return false;
            }
            if (obj is F5Address)
            {
                return this.Equals((F5Address)obj);
            }
            if (obj is IPAddress)
            {
                var f5address = new F5Address(((IPAddress)obj).ToString());
                return this.Equals(f5address);
            }
            if (obj is string)
            {
                var f5address = new F5Address((string)obj);
                return this.Equals(f5address);
            }
            return false;
        }

        public bool Equals(F5Address other)
        {
            return IPAddress.Equals(other.IPAddress) && RouteDomain.Equals(other.RouteDomain);
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
                F5Address f5address = new F5Address(address);
                return IPAddress.ToString() == f5address.IPAddress.ToString();
            }
        }

        public override string ToString()
        {
            return String.Format("{0}{1:\\%0}", IPAddress, RouteDomain);
        }

        public static implicit operator F5Address(IPAddress value)
        {
            return new F5Address(value.ToString());
        }
        public static implicit operator F5Address(string value)
        {
            return new F5Address(value);
        }
        public static implicit operator IPAddress(F5Address value)
        {
            return value.IPAddress;
        }
        public static implicit operator string(F5Address value)
        {
            return String.Format("{0}{1:\\%0}", value.IPAddress, value.RouteDomain);
        }
        public static bool IsMatch(F5Address filter, string address)
        {
            return filter.IsMatch(address);
        }
        public static bool IsMatch(F5Address[] filter, string address)
        {
            foreach(F5Address f in filter)
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