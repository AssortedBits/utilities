using System.Net.NetworkInformation;

class Pinger
{

    static string PingAddr(string host)
    {
        using (Ping pingSender = new Ping())
        {
            PingOptions options = new PingOptions();

            // Create a buffer of 32 bytes of data to be transmitted.
            string data = "55555555555555555555555555555555";
            byte[] buffer = System.Text.Encoding.ASCII.GetBytes(data);
            TimeSpan timeout = new(0, 0, 5);
            PingReply reply =
                pingSender.Send(
                    host,
                    (int)timeout.TotalMilliseconds,
                    buffer,
                    options);
            return
                host +
                (
                    (reply.Status != IPStatus.Success)
                    ? "\t\tTIMED OUT"
                    : "\t\t: " + reply.RoundtripTime + "ms"
                );
        }
    }

    static void Main(string[] args)
    {
        List<string> hosts = new();
        foreach (var arg in args)
            hosts.Add(arg);

        //Make sure we don't hammer faster than once every 3s.
        TimeSpan minIterPulse = new(0, 0, 5);

        while (true)
        {
            Console.WriteLine();
            Console.WriteLine(DateTime.Now);
            Console.WriteLine();
            List<Task<string>> tasks = new();

            tasks.Add(
                Task<string>.Run(
                    () => { Thread.Sleep(minIterPulse); return ""; }
                )
            );

            foreach (string host in hosts)
            {
                tasks.Add(
                    Task<string>.Run(
                        () => { return PingAddr(host); }));
            }
            foreach (Task<string> task in tasks)
            {
                string result = task.Result;
                if(0 != result.Length)  //My hack to shoehorn-in the min pulse length.
                    Console.WriteLine(task.Result);
            }

            System.GC.Collect();
            System.GC.WaitForPendingFinalizers();
            System.GC.Collect();
        }
    }
}