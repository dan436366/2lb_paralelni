using System;
using System.Diagnostics;
using System.Threading;

class ThreadMinFinder
{
    private const int ARRAY_SIZE = 100_000_000;
    private static readonly Random random = new Random();

    class MinElement
    {
        public int Value { get; set; }
        public int Index { get; set; }

        public MinElement(int value, int index)
        {
            Value = value;
            Index = index;
        }
    }

    private static readonly object lockObject = new object();
    private static MinElement globalMin = new MinElement(int.MaxValue, -1);

    static void Main()
    {
        Console.Write("Enter number of threads: ");
        int threadsCount;
        if (!int.TryParse(Console.ReadLine(), out threadsCount) || threadsCount < 1)
        {
            Console.WriteLine("Invalid thread count. Defaulting to 4 threads.");
            threadsCount = 4;
        }

        int[] array = GenerateArray();

        Stopwatch stopwatch = Stopwatch.StartNew();
        MinElement result = FindMinimumParallel(array, threadsCount);
        stopwatch.Stop();

        Console.WriteLine($"Minimum element: {result.Value} at index: {result.Index}");
        Console.WriteLine($"Time taken: {stopwatch.ElapsedMilliseconds} ms");
    }

    private static int[] GenerateArray()
    {
        int[] array = new int[ARRAY_SIZE];
        for (int i = 0; i < array.Length; i++)
        {
            array[i] = random.Next(1000000);
        }
        int randomIndex = random.Next(ARRAY_SIZE);
        array[randomIndex] = -random.Next(1, 1001);
        return array;
    }

    private static MinElement FindMinimumParallel(int[] array, int threadsCount)
    {
        globalMin = new MinElement(int.MaxValue, -1);
        CountdownEvent countdownEvent = new CountdownEvent(threadsCount);

        for (int i = 0; i < threadsCount; i++)
        {
            int threadIndex = i;
            Thread thread = new Thread(() =>
            {
                int elementsPerThread = array.Length / threadsCount;
                int startIndex = threadIndex * elementsPerThread;
                int endIndex = (threadIndex == threadsCount - 1) ?
                    array.Length : startIndex + elementsPerThread;

                MinElement localMin = new MinElement(int.MaxValue, -1);
                for (int j = startIndex; j < endIndex; j++)
                {
                    if (array[j] < localMin.Value)
                    {
                        localMin.Value = array[j];
                        localMin.Index = j;
                    }
                }

                lock (lockObject)
                {
                    if (localMin.Value < globalMin.Value)
                    {
                        globalMin = localMin;
                    }
                }

                countdownEvent.Signal();
            });
            thread.Start();
        }

        countdownEvent.Wait();
        return globalMin;
    }
}
