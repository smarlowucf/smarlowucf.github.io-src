===================================
A Pythonic Journey Into Concurrency
===================================

:Date: 2019-01-26 10:20
:Modified: 2019-01-26 19:30
:Category: Python
:Tags: async, python
:Slug: async-python
:Authors: Sean Marlow
:Summary: A look at concurrency in Python

Synchronous vs Asynchronous
---------------------------

**Synchronous**
   Sequential set of actions or tasks. One process at a time, when one
   finishes the next starts.

**Asynchronous**
   Processes or tasks can take place concurrently during execution of a
   program.

**Concurrency**
   When several computations are executed during overlapping time
   periods. Concurrency does not necessarily mean parallelism.

Asynchronous
------------

Threads (Sometimes)
~~~~~~~~~~~~~~~~~~~

Threads are lighter than processes however in Python they cannot run in
parallel. Due to the GIL (Global Interpreter Lock) threads should not be
used for CPU bound tasks. Using threads with CPU heavy tasks leads to
code that basically runs synchronously.

Threads do work well with I/O bound code though, since most of the time
is spent waiting on a response.

Processes
~~~~~~~~~

Processes are heavier than threads but do not have the same issue with
the GIL. Thus multi-processing works well for CPU and I/O bound code.

There are a few options in Python that provide multi-processing. But we
will focus on the asyncio event loop framework and async/await syntax.

Workers (Celery, RQ)
~~~~~~~~~~~~~~~~~~~~

We won’t go into this option but it would mainly be useful with
distributed apps, web apps and/or service oriented projects. Celery and
RQ are distributed task queues which can concurrently run jobs with a
pool of workers. These can be either threads, processes or combination
of the two.

How does the code compare?
^^^^^^^^^^^^^^^^^^^^^^^^^^

Synchronous
-----------

.. code-block:: python
   :linenos: table

   import time
   import timeit


   def sleep(n):
       print('Start sleep')
       time.sleep(n)
       print('Stop sleep')


   def main():
       sleep(.8)
       sleep(.9)

   start_time = timeit.default_timer()

   main()

   elapsed = timeit.default_timer() - start_time
   print('Sync took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python sync_sleep.py
   Start sleep
   Stop sleep  
   Start sleep
   Stop sleep
   Sync took 1.70s

Each call to sleep function happens sequentially.

Multi-thread
------------

.. code-block:: python
   :linenos: table

   import time
   import timeit

   from threading import Thread


   def sleep(n):
       print('Start sleep')
       time.sleep(n)
       print('Stop sleep')


   def main():
       s1 = Thread(target=sleep, args=(.8,))
       s2 = Thread(target=sleep, args=(.9,))

       s1.start()
       s2.start()

       s1.join()  
       s2.join()


   start_time = timeit.default_timer()

   main()

   elapsed = timeit.default_timer() - start_time
   print('Thread took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python thread_sleep.py
   Start sleep
   Start sleep  
   Stop sleep
   Stop sleep
   Thread took 0.90s  

Both threads have been started, join waits for execution to finish.
Both threads start the sleep function concurrently.
Execution time is equal to longest sleep function call.

Multi-process w/ asyncio
------------------------

.. code-block:: python
   :linenos: table

   import asyncio
   import timeit


   async def sleep(n):  
       print('Start sleep')
       await asyncio.sleep(n)  
       print('Stop sleep')


   async def main():
       tasks = [sleep(.8), sleep(.9)]
       await asyncio.wait(tasks)  

   start_time = timeit.default_timer()

   loop = asyncio.get_event_loop()
   loop.run_until_complete(main())  
   loop.close()

   elapsed = timeit.default_timer() - start_time
   print('Async took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python async_sleep.py
   Start sleep
   Start sleep
   Stop sleep
   Stop sleep
   Async took 0.90s

-  The ``async def`` denotes this function as a coroutine. This also can
   be denoted with the ``@asyncio.coroutine`` decorator.

-  When we hit an await statement the future or coroutine is added to
   event loop and we yield control back to the loop.

-  The wait function wraps the coroutines with ensure_future which
   returns a future instance for each.

-  Ensures the loop is running until all the tasks finished.

Asyncio
-------

Asyncio provides an infrastructure for writing single-threaded
concurrent code using coroutines. The execution of coroutines is managed
via an event loop through the use of cooperative or non-preemptive
multitasking.

Coroutines
~~~~~~~~~~

In Python a coroutine is a generator that can yield values and receive
values from the outside. This allows the function to pause execution
just lke a generator and yield control.

As noted above coroutines are denoted in one of two ways as of Python
3.5. Generator based using a decorator and ``yield from`` as well as
natively using the keywords ``async``/``await``.

   **Note**

   Native coroutines cannot contain any ``yield`` statements.

Generators
~~~~~~~~~~

Functions that can yield a value and pause execution. Control is
returned to the calling scope. In the case of asyncio this is the event
loop. A generator object is an iterable and has the ``next`` function.
This is allows the calling function to iterate over it and get values
one by one.

Tasks / Futures
~~~~~~~~~~~~~~~

A future is like a promise. It is a place holder to say that a value
will exist in the future. In python you can await futures, tasks and
coroutines. When the future is finished it returns the value of the
underlying function or an exception.

A Task is a subclass of future that wraps a coroutine. When the
coroutine finishes, the result of the Task is realized.

Event Loop
~~~~~~~~~~

An event loop runs constantly until it’s explicitly stopped. The asyncio
loop continuously iterates over a task queue. With each future the event
loop calls the ``next`` function which picks up where it left off. When
another coroutine or future is called the active future is suspended and
cooperatively/voluntarily yields control. This is called a context
switch. The event loop then moves to the next task.

Async/await
~~~~~~~~~~~

Async/await can be considered an API to access event loops. This is idea
is discussed by `David
Beazley <http://pyvideo.org/python-brasil-2015/keynote-david-beazley-topics-of-interest-python-asyncio.html>`__.
The syntax is not tied directly to asyncio and can be used with other
event loop implementations such as Curio and Trio.

As of Python 3.5 the async/await syntax was added. This is similar to
the previous decorator based syntax but there are key differences.

A (native) ``async def`` defined coroutine can only do two things,
``await`` and ``return``. An error is raised if a ``yield`` is within a
native coroutine. The decorator based coroutine uses ``yield from``
instead of ``await``.

Other Libraries
---------------

Curio
~~~~~

A library that’s similar to and can replace the asyncio event loop for
concurrent programming. It uses the same async/await syntax and
cooperative multitasking just like asyncio. However, the way it handles
events is very different and the API is much smaller.
`Curio <https://curio.readthedocs.io/en/latest/>`__ performs around 20%
faster than comparable asyncio code.

Trio
~~~~

`Trio <https://trio.readthedocs.io/en/latest/index.html>`__ is also an
async/await native I/O library for Python. Its main purpose is to help
you write programs that do multiple things at the same time with
parallelized I/O. Trio draws inspiration from many sources including
Dave Beazley’s Curio.

   **Note**

   Trio is not production ready.

 

A Few More Examples
-------------------

CPU Bound Synchronous
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python
   :linenos: table

   import timeit


   def fib(n):
       if n < 2:
           return 1
       else:
           return fib(n - 1) + fib(n - 2)


   start_time = timeit.default_timer()

   fib(33)
   fib(34)

   elapsed = timeit.default_timer() - start_time
   print('Sync took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python sync_fib.py
   Sync took 2.91s

CPU Bound Multi-thread
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python
   :linenos: table

   import timeit

   from threading import Thread


   def fib(n):
       if n < 2:
           return 1
       else:
           return fib(n - 1) + fib(n - 2)


   def main():
       f1 = Thread(target=fib, args=(33,))
       f2 = Thread(target=fib, args=(34,))

       f1.start()
       f2.start()

       f1.join()
       f2.join()


   start_time = timeit.default_timer()

   main()

   elapsed = timeit.default_timer() - start_time
   print('Thread took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python thread_fib.py
   Thread took 2.86s  

Ended up taking about the same time as the synchronous code. Not
surprising since each thread is utilizing 100% CPU during execution.
The GIL blocks the threads from running concurrently.

CPU Bound Multi-process w/ asyncio
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python
   :linenos: table

   import asyncio
   import timeit


   async def fib(n):
       if n < 2:
           return 1
       else:
           return await fib(n - 1) + await fib(n - 2)


   async def main():
       tasks = [fib(33), fib(34)]
       await asyncio.wait(tasks)


   start_time = timeit.default_timer()

   loop = asyncio.get_event_loop()
   loop.run_until_complete(main())
   loop.close()

   elapsed = timeit.default_timer() - start_time
   print('Async took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python async_fib.py
   Async took 6.34s  

What!? Isn’t asyncio great for CPU bound concurrency? The problem
here is a bad algorithm and the overhead of context switching.
Because fib is recursive every call to a new fib coroutine adds a
task to the queue. This adds up quickly and requires an excessive
number of context switches.

With Iterative Fibonacci Algorithm
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python
   :linenos: table

   ...
   def fib(n):
       if n < 2:
           return 1

       fib = 1
       prev = 1
       for i in range(2, n):
           prev, fib = fib, fib + prev
   ...

.. raw:: html

   &nbsp;

.. code-block:: bash

   $ python sync_fib_iter.py
   Sync took 1.46s
   $ python thread_fib_iter.py
   Thread took 1.74s
   $ python async_fib_iter.py
   Async took 0.50s  

Now we don’t have all of the context switches that come with a
recursive algorithm.

Asyncio Iterative Fibonacci Example Using Process Pool
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python
   :linenos: table

   import asyncio
   import concurrent.futures
   import timeit


   def fib(n):  
       if n < 2:
           return 1

       fib = 1
       prev = 1
       for i in range(2, n):
           prev, fib = fib, fib + prev


   async def main():
       executor = concurrent.futures.ProcessPoolExecutor()  
       loop = asyncio.get_event_loop()

       tasks = [
           loop.run_in_executor(executor, fib, i)  
           for i in range(10000, 11000)
       ]
       await asyncio.wait(tasks)


   start_time = timeit.default_timer()

   loop = asyncio.get_event_loop()
   loop.run_until_complete(main())
   loop.close()

   elapsed = timeit.default_timer() - start_time
   print('Async took %0.2fs' % elapsed)

-  Here the fib function is blocking. It is not a coroutine thus we need
   some way to run the function in a separate process.

-  To do so we can use a process pool from the concurrent futures
   library.

-  We generate a list of tasks each running fib in the process pool.

First Completed
~~~~~~~~~~~~~~~

.. code-block:: python
   :linenos: table

   import asyncio
   import timeit
   from concurrent.futures import FIRST_COMPLETED


   async def sleep(n):
       print('Start sleep')
       await asyncio.sleep(n)
       print('Stop sleep')


   async def main():
       tasks = [sleep(.8), sleep(.9)]
       done, pending = await asyncio.wait(
           tasks,
           return_when=FIRST_COMPLETED  
       )

       for future in pending:
           future.cancel()  

   start_time = timeit.default_timer()

   loop = asyncio.get_event_loop()
   loop.run_until_complete(main())
   loop.close()

   elapsed = timeit.default_timer() - start_time
   print('First took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   Start sleep
   Start sleep
   Stop sleep
   Firt took 0.80s  

-  Call asyncio.wait with FIRST_COMPLETED flag to stop after first task
   completes.

-  Any tasks/futures that have not completed should be canceled.

-  Execution time is same as the shortest sleep call.

How does Curio stack up against asyncio?
----------------------------------------

As you can see Curio syntax is closer to threading than asycnio.
However, it is also single threaded just like asyncio.

.. code-block:: python
   :linenos: table

   import curio
   import timeit


   def fib(n):
       if n < 2:
           return 1

       fib = 1
       prev = 1
       for i in range(2, n):
           prev, fib = fib, fib + prev


   async def main():
       tasks = []
       for i in range(10000, 11000):
           task = await curio.spawn(curio.run_in_process, fib, i)
           tasks.append(task)

       for task in tasks:
           await task.join()


   start_time = timeit.default_timer()

   curio.run(main)

   elapsed = timeit.default_timer() - start_time
   print('Curio took %0.2fs' % elapsed)

.. raw:: html

   &nbsp;

.. code-block:: bash

   Curio took 0.46s  

Slightly more efficient than asyncio. Not surprising since Curio is a
leaner api and a bit more lightweight.
