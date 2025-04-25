package org.example;

import java.util.Random;
import java.util.Scanner;

public class ThreadMinFinder {
    private static final int ARRAY_SIZE = 100_000_000;
    private static final Random random = new Random();

    static class MinElement {
        int value;
        int index;

        public MinElement(int value, int index) {
            this.value = value;
            this.index = index;
        }
    }

    private static final Object lock = new Object();
    private static MinElement globalMin = new MinElement(Integer.MAX_VALUE, -1);
    private static int finishedThreads = 0;

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.print("Enter number of threads: ");
        int threadsCount = scanner.nextInt();
        scanner.close();

        int[] array = generateArray();

        long startTime = System.currentTimeMillis();
        MinElement result = findMinimumParallel(array, threadsCount);
        long endTime = System.currentTimeMillis();

        System.out.println("Minimum element: " + result.value + " at index: " + result.index);
        System.out.println("Time taken: " + (endTime - startTime) + " ms");
    }

    private static int[] generateArray() {
        int[] array = new int[ARRAY_SIZE];
        for (int i = 0; i < array.length; i++) {
            array[i] = random.nextInt(1000000);
        }
        int randomIndex = random.nextInt(ARRAY_SIZE);
        array[randomIndex] = -random.nextInt(1000) - 1;
        return array;
    }

    private static MinElement findMinimumParallel(int[] array, int threadsCount) {
        globalMin = new MinElement(Integer.MAX_VALUE, -1);
        finishedThreads = 0;

        for (int i = 0; i < threadsCount; i++) {
            final int threadIndex = i;
            Thread thread = new Thread(() -> {
                int elementsPerThread = array.length / threadsCount;
                int startIndex = threadIndex * elementsPerThread;
                int endIndex = (threadIndex == threadsCount - 1) ?
                        array.length : startIndex + elementsPerThread;

                MinElement localMin = new MinElement(Integer.MAX_VALUE, -1);
                for (int j = startIndex; j < endIndex; j++) {
                    if (array[j] < localMin.value) {
                        localMin.value = array[j];
                        localMin.index = j;
                    }
                }

                synchronized (lock) {
                    if (localMin.value < globalMin.value) {
                        globalMin = localMin;
                    }
                    finishedThreads++;
                    if (finishedThreads == threadsCount) {
                        lock.notifyAll();
                    }
                }
            });
            thread.start();
        }

        synchronized (lock) {
            while (finishedThreads < threadsCount) {
                try {
                    lock.wait();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    System.err.println("Main thread interrupted: " + e.getMessage());
                }
            }
        }

        return globalMin;
    }
}
