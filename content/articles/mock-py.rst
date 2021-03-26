===========================
Unit test mocking in Python
===========================

:Date: 2021-03-25 14:44
:Modified: 2021-03-25 14:44
:Category: Python
:Tags: mock, testing, unit test, integration test, python
:Slug: mock-python
:Authors: Sean Marlow
:Summary: An overview of Python mocking and testing techniques

Overview
--------

When writing automated tests for Python code it can be helpful to use
mocking techniques to improve quality and reliability of a test suite.

Some reasons you may want to use mock:

- Code makes HTTP requests to an external service.
- Covering difficult to reach areas of a codebase such as except blocks
  and if blocks.
- To limit test scope such as in a unit test.
- To prevent creating unnecessary or costly artifacts when running tests.

**mock**
   Built in (Python 3.3+) mocking library. Allows you to replace parts
   of your code with mock objects. Assertions can be made about how
   these objects have been used. **unittest.mock**

**VCR.py**
   VCR.py records all HTTP interactions that take place through the
   libraries it supports (requests) and serializes and writes them to
   a flat file. On subsequent test runs VCR.py intercepts requests and
   returns the recorded response which provides reliability and
   consistency to a test. Another similar library is **betamax**.

**moto**
   A library that simplifies mocking of code that interacts with boto3.
   This allows you to write integration tests without actually sending
   requests to AWS.

Mock
----

Mock/MagicMock
~~~~~~~~~~~~~~

Mock and MagicMock objects create all attributes and methods as you access
them and store details of how they have been used. You can configure them,
to specify return values or limit what attributes are available, and then
make assertions about how they have been used.

MagicMock is a subclass of Mock with default implementations of most of
the magic methods.

For a default Mock object any method can be called and the assertions can
be made.

.. code-block:: bash

   >>> from unittest.mock import Mock
   >>> mock = Mock()
   >>> mock.do_something(34)
   <Mock name='mock.do_something()' id='140507807331520'>
   >>> mock.do_something.assert_called_once_with(34)
   >>> mock.do_something_else.assert_called_once_with(34)
   Traceback (most recent call last):
     File "<stdin>", line 1, in <module>
     File "/usr/lib64/python3.8/unittest/mock.py", line 924, in assert_called_once_with
       raise AssertionError(msg)
   AssertionError: Expected 'do_something_else' to be called once. Called 0 times.

The MagicMock object by default handles most of the magic methods. For example
if the object is used as a dictionary both __setitem__ is called when setting
the '3' key to 'fish.

.. code-block:: bash

   >>> from unittest.mock import MagicMock
   >>> mock = MagicMock()
   >>> mock[3] = 'fish'
   >>> mock.__setitem__.assert_called_with(3, 'fish')
   >>> mock.__getitem__.return_value = 'result'
   >>> mock[2]
   'result'
   >>> 

.. code-block:: bash

   >>> from unittest.mock import MagicMock
   mock = MagicMock()
   >>> int(mock)
   1
   >>> len(mock)
   0
   >>> list(mock)
   []
   >>> object() in mock
   False
   >>> 

Some of the built in assertion methods that can be called on a mock object
include; assert_called_once_with, assert_called, assert_not_called,
call_count, reset_mock.

.. code-block:: bash

   >>> from unittest.mock import MagicMock
   >>> mock = MagicMock()
   >>> mock.add_log('This is a secret log message!')
   <MagicMock name='mock.add_log()' id='140507806964272'>
   >>> mock.add_log.assert_called_once_with('This is a secret log message!')
   >>> mock.add_log.assert_called()
   >>> assert mock.add_log.call_count == 1
   >>> mock.add_log('Yet another log message.')
   <MagicMock name='mock.add_log()' id='140507806964272'>
   >>> assert mock.add_log.call_count == 2
   >>> mock.reset_mock()
   >>> assert mock.add_log.call_count == 2
   Traceback (most recent call last):
     File "<stdin>", line 1, in <module>
   AssertionError
   >>> mock.add_log.assert_not_called()
   >>> 

Additionally you can make more complex assertions based on multiple calls
based on order of the calls.

.. code-block:: bash

   >>> from unittest.mock import MagicMock
   >>> mock = MagicMock()
   >>> mock.add_int(23)
   <MagicMock name='mock.add_int()' id='140507807032800'>
   >>> mock.add_int(32)
   <MagicMock name='mock.add_int()' id='140507807032800'>
   >>> from unittest.mock import call
   >>> mock.add_int.assert_has_calls([call(23), call(32)])

You can also set the return values for method and attribute access. With
the side effect method you can set an ordered list of return values
and/or have a method raise a specific exception.

.. code-block:: bash

   >>> from unittest.mock import MagicMock
   >>> mock = MagicMock()
   >>> mock.get_person.return_value = {'name': 'Bob', 'id': 1}
   >>> mock.get_person('bob')
   {'name': 'Bob', 'id': 1}
   >>> mock.get_person.side_effect = Exception('Bob was not found')
   >>> mock.get_person('bob')
   Traceback (most recent call last):
     File "<stdin>", line 1, in <module>
     File "/usr/lib64/python3.8/unittest/mock.py", line 1081, in __call__
       return self._mock_call(*args, **kwargs)
     File "/usr/lib64/python3.8/unittest/mock.py", line 1085, in _mock_call
       return self._execute_mock_call(*args, **kwargs)
     File "/usr/lib64/python3.8/unittest/mock.py", line 1140, in _execute_mock_call
       raise effect
   Exception: Bob was not found
   >>> mock.next.side_effect = [1, 2, StopIteration]
   >>> mock.next()
   1
   >>> mock.next()
   2
   >>> mock.next()
   Traceback (most recent call last):
     File "<stdin>", line 1, in <module>
     File "/usr/lib64/python3.8/unittest/mock.py", line 1081, in __call__
       return self._mock_call(*args, **kwargs)
     File "/usr/lib64/python3.8/unittest/mock.py", line 1085, in _mock_call
       return self._execute_mock_call(*args, **kwargs)
     File "/usr/lib64/python3.8/unittest/mock.py", line 1144, in _execute_mock_call
       raise result
   StopIteration
   >>> mock.name = 'Bob'
   >>> mock.name
   'Bob'

You can use autospec to ensure that the mock object or function has the same
API as the mocked object or function. This can be done with the
`create_autospec` function.

.. code-block:: bash

   >>> from unittest.mock import create_autospec
   >>> def function(a, b, c):
   ...     pass
   ... 
   >>> mock_function = create_autospec(function, return_value='fishy')
   >>> mock_function('wrong arguments')
   Traceback (most recent call last):
     File "<stdin>", line 1, in <module>
     File "<string>", line 2, in function
     File "/usr/lib64/python3.8/unittest/mock.py", line 181, in checksig
       sig.bind(*args, **kwargs)
     File "/usr/lib64/python3.8/inspect.py", line 3037, in bind
       return self._bind(args, kwargs)
     File "/usr/lib64/python3.8/inspect.py", line 2952, in _bind
       raise TypeError(msg) from None
   TypeError: missing a required argument: 'b'

Or it can be set on a mock object during creation. The spec argument
denotes what object to use as specification for attributes and
methods. This will also check the arguments for any method calls.

.. code-block:: bash

   >>> from unittest.mock import MagicMock
   >>> from urllib import request
   >>> mock = MagicMock(spec=request.Request)
   >>> mock.assret_called_with
   Traceback (most recent call last):
     File "<stdin>", line 1, in <module>
     File "/usr/lib64/python3.8/unittest/mock.py", line 637, in __getattr__
       raise AttributeError("Mock object has no attribute %r" % name)
   AttributeError: Mock object has no attribute 'assret_called_with'
   >>> dir(mock)
   ['add_header', 'add_unredirected_header', 'assert_any_call',
   'assert_called', 'assert_called_once', 'assert_called_once_with',
   'assert_called_with', 'assert_has_calls', 'assert_not_called',
   'attach_mock', 'autospec', 'call_args', 'call_args_list', 'call_count',
   'called', 'configure_mock', 'data', 'full_url', 'get_full_url',
   'get_header', 'get_method', 'has_header', 'has_proxy', 'header_items',
   'method_calls', 'mock_add_spec', 'mock_calls', 'remove_header',
   'reset_mock', 'return_value', 'set_proxy', 'side_effect']
   >>> dir(request.Request)
   ['add_header', 'add_unredirected_header', 'data', 'full_url',
   'get_full_url', 'get_header', 'get_method', 'has_header', 'has_proxy',
   'header_items', 'remove_header', 'set_proxy']

Patch
~~~~~

Patch acts as a function decorator, class decorator or a context manager.
It patches an object or function with a mock object which can be used in
a test to make assertions.

The first example of patching uses a helper function that can be helpful
in mocking the open built in. This works for mocking the read and write of
files.

.. code-block:: bash

   >>> from unittest.mock import mock_open, patch
   >>> with patch('__main__.open', mock_open(read_data='Text in a file.')) as m:
   ...     with open('foo') as h:
   ...         result = h.read()
   ...
   >>> result
   'Text in a file.'
   >>> with patch('__main__.open', mock_open()) as m:
   ...     with open('foo', 'w') as h:
   ...         h.write('Write some stuff.')
   ...
   >>> m.mock_calls
   [call('foo', 'w'),
   call().__enter__(),
   call().write('Write some stuff.'),
   call().__exit__(None, None, None)]
   >>> handle = m()
   >>> handle.write.assert_called_once_with('Write some stuff.')