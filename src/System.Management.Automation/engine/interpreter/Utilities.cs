// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.Diagnostics;
using System.Dynamic;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Threading;
using AstUtils = System.Management.Automation.Interpreter.Utils;

namespace System.Management.Automation.Interpreter
{
    internal static class TypeUtils
    {
        internal static Type GetNonNullableType(this Type type)
        {
            if (IsNullableType(type))
            {
                return type.GetGenericArguments()[0];
            }
            return type;
        }

        internal static Type GetNullableType(Type type)
        {
            Debug.Assert(type != null, "type cannot be null");
            if (type.IsValueType && !IsNullableType(type))
            {
                return typeof(Nullable<>).MakeGenericType(type);
            }
            return type;
        }

        internal static bool IsNullableType(Type type)
        {
            return type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Nullable<>);
        }

        internal static bool IsBool(Type type)
        {
            return GetNonNullableType(type) == typeof(bool);
        }

        internal static bool IsNumeric(Type type)
        {
            type = GetNonNullableType(type);
            if (!type.IsEnum)
            {
                switch (type.GetTypeCode())
                {
                    case TypeCode.Char:
                    case TypeCode.SByte:
                    case TypeCode.Byte:
                    case TypeCode.Int16:
                    case TypeCode.Int32:
                    case TypeCode.Int64:
                    case TypeCode.Double:
                    case TypeCode.Single:
                    case TypeCode.UInt16:
                    case TypeCode.UInt32:
                    case TypeCode.UInt64:
                        return true;
                }
            }
            return false;
        }

        internal static bool IsNumeric(TypeCode typeCode)
        {
            switch (typeCode)
            {
                case TypeCode.Char:
                case TypeCode.SByte:
                case TypeCode.Byte:
                case TypeCode.Int16:
                case TypeCode.Int32:
                case TypeCode.Int64:
                case TypeCode.Double:
                case TypeCode.Single:
                case TypeCode.UInt16:
                case TypeCode.UInt32:
                case TypeCode.UInt64:
                    return true;
            }
            return false;
        }

        internal static bool IsArithmetic(Type type)
        {
            type = GetNonNullableType(type);
            if (!type.IsEnum)
            {
                switch (type.GetTypeCode())
                {
                    case TypeCode.Int16:
                    case TypeCode.Int32:
                    case TypeCode.Int64:
                    case TypeCode.Double:
                    case TypeCode.Single:
                    case TypeCode.UInt16:
                    case TypeCode.UInt32:
                    case TypeCode.UInt64:
                        return true;
                }
            }
            return false;
        }
    }

    internal static class ArrayUtils
    {
        internal static T[] AddLast<T>(this IList<T> list, T item)
        {
            T[] res = new T[list.Count + 1];
            list.CopyTo(res, 0);
            res[list.Count] = item;
            return res;
        }
    }

    internal static partial class DelegateHelpers
    {
        #region Generated Maximum Delegate Arity

        // *** BEGIN GENERATED CODE ***
        // generated by function: gen_max_delegate_arity from: generate_dynsites.py

        private const int MaximumArity = 17;

        // *** END GENERATED CODE ***

        #endregion

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        internal static Type MakeDelegate(Type[] types)
        {
            Debug.Assert(types != null && types.Length > 0);

            // Can only used predefined delegates if we have no byref types and
            // the arity is small enough to fit in Func<...> or Action<...>
            if (types.Length > MaximumArity || types.Any(t => t.IsByRef))
            {
                throw Assert.Unreachable;
                //return MakeCustomDelegate(types);
            }

            Type returnType = types[types.Length - 1];
            if (returnType == typeof(void))
            {
                Array.Resize(ref types, types.Length - 1);
                switch (types.Length)
                {
                    case 0: return typeof(Action);
                    #region Generated Delegate Action Types

                    // *** BEGIN GENERATED CODE ***
                    // generated by function: gen_delegate_action from: generate_dynsites.py

                    case 1: return typeof(Action<>).MakeGenericType(types);
                    case 2: return typeof(Action<,>).MakeGenericType(types);
                    case 3: return typeof(Action<,,>).MakeGenericType(types);
                    case 4: return typeof(Action<,,,>).MakeGenericType(types);
                    case 5: return typeof(Action<,,,,>).MakeGenericType(types);
                    case 6: return typeof(Action<,,,,,>).MakeGenericType(types);
                    case 7: return typeof(Action<,,,,,,>).MakeGenericType(types);
                    case 8: return typeof(Action<,,,,,,,>).MakeGenericType(types);
                    case 9: return typeof(Action<,,,,,,,,>).MakeGenericType(types);
                    case 10: return typeof(Action<,,,,,,,,,>).MakeGenericType(types);
                    case 11: return typeof(Action<,,,,,,,,,,>).MakeGenericType(types);
                    case 12: return typeof(Action<,,,,,,,,,,,>).MakeGenericType(types);
                    case 13: return typeof(Action<,,,,,,,,,,,,>).MakeGenericType(types);
                    case 14: return typeof(Action<,,,,,,,,,,,,,>).MakeGenericType(types);
                    case 15: return typeof(Action<,,,,,,,,,,,,,,>).MakeGenericType(types);
                    case 16: return typeof(Action<,,,,,,,,,,,,,,,>).MakeGenericType(types);

                        // *** END GENERATED CODE ***

                        #endregion
                }
            }
            else
            {
                switch (types.Length)
                {
                    #region Generated Delegate Func Types

                    // *** BEGIN GENERATED CODE ***
                    // generated by function: gen_delegate_func from: generate_dynsites.py

                    case 1: return typeof(Func<>).MakeGenericType(types);
                    case 2: return typeof(Func<,>).MakeGenericType(types);
                    case 3: return typeof(Func<,,>).MakeGenericType(types);
                    case 4: return typeof(Func<,,,>).MakeGenericType(types);
                    case 5: return typeof(Func<,,,,>).MakeGenericType(types);
                    case 6: return typeof(Func<,,,,,>).MakeGenericType(types);
                    case 7: return typeof(Func<,,,,,,>).MakeGenericType(types);
                    case 8: return typeof(Func<,,,,,,,>).MakeGenericType(types);
                    case 9: return typeof(Func<,,,,,,,,>).MakeGenericType(types);
                    case 10: return typeof(Func<,,,,,,,,,>).MakeGenericType(types);
                    case 11: return typeof(Func<,,,,,,,,,,>).MakeGenericType(types);
                    case 12: return typeof(Func<,,,,,,,,,,,>).MakeGenericType(types);
                    case 13: return typeof(Func<,,,,,,,,,,,,>).MakeGenericType(types);
                    case 14: return typeof(Func<,,,,,,,,,,,,,>).MakeGenericType(types);
                    case 15: return typeof(Func<,,,,,,,,,,,,,,>).MakeGenericType(types);
                    case 16: return typeof(Func<,,,,,,,,,,,,,,,>).MakeGenericType(types);
                    case 17: return typeof(Func<,,,,,,,,,,,,,,,,>).MakeGenericType(types);

                        // *** END GENERATED CODE ***

                        #endregion
                }
            }
            throw Assert.Unreachable;
        }
    }

    internal class ScriptingRuntimeHelpers
    {
        internal static object Int32ToObject(int i)
        {
            return i;
        }

        internal static object BooleanToObject(bool b)
        {
            return b ? True : False;
        }

        internal static readonly MethodInfo BooleanToObjectMethod = typeof(ScriptingRuntimeHelpers).GetMethod("BooleanToObject");
        internal static readonly MethodInfo Int32ToObjectMethod = typeof(ScriptingRuntimeHelpers).GetMethod("Int32ToObject");

        internal static object True = true;
        internal static object False = false;

        internal static object GetPrimitiveDefaultValue(Type type)
        {
            switch (type.GetTypeCode())
            {
                case TypeCode.Boolean: return ScriptingRuntimeHelpers.False;
                case TypeCode.SByte: return default(SByte);
                case TypeCode.Byte: return default(Byte);
                case TypeCode.Char: return default(Char);
                case TypeCode.Int16: return default(Int16);
                case TypeCode.Int32: return ScriptingRuntimeHelpers.Int32ToObject(0);
                case TypeCode.Int64: return default(Int64);
                case TypeCode.UInt16: return default(UInt16);
                case TypeCode.UInt32: return default(UInt32);
                case TypeCode.UInt64: return default(UInt64);
                case TypeCode.Single: return default(Single);
                case TypeCode.Double: return default(Double);
                case TypeCode.DateTime: return default(DateTime);
                case TypeCode.Decimal: return default(Decimal);
                // TypeCode.Empty:  null;
                // TypeCode.Object: default(object) == null;
                // TypeCode.DBNull: default(DBNull) == null;
                // TypeCode.String: default(string) == null;
                default: return null;
            }
        }
    }

    /// <summary>
    /// Wraps all arguments passed to a dynamic site with more arguments than can be accepted by a Func/Action delegate.
    /// The binder generating a rule for such a site should unwrap the arguments first and then perform a binding to them.
    /// </summary>
    internal sealed class ArgumentArray
    {
        private readonly object[] _arguments;

        // the index of the first item _arguments that represents an argument:
        private readonly int _first;

        // the number of items in _arguments that represent the arguments:

        internal ArgumentArray(object[] arguments, int first, int count)
        {
            _arguments = arguments;
            _first = first;
            Count = count;
        }

        public int Count { get; }

        public object GetArgument(int index)
        {
            //ContractUtils.RequiresArrayIndex(_arguments, index, "index");
            return _arguments[_first + index];
        }

        public DynamicMetaObject GetMetaObject(Expression parameter, int index)
        {
            return DynamicMetaObject.Create(
                GetArgument(index),
                Expression.Call(
                    s_getArgMethod,
                    AstUtils.Convert(parameter, typeof(ArgumentArray)),
                    AstUtils.Constant(index)
                )
            );
        }

        //[CLSCompliant(false)]
        public static object GetArg(ArgumentArray array, int index)
        {
            return array._arguments[array._first + index];
        }

        private static readonly MethodInfo s_getArgMethod = new Func<ArgumentArray, int, object>(GetArg).GetMethodInfo();
    }

    internal static class ExceptionHelpers
    {
        private const string prevStackTraces = "PreviousStackTraces";

        /// <summary>
        /// Updates an exception before it's getting re-thrown so
        /// we can present a reasonable stack trace to the user.
        /// </summary>
        public static Exception UpdateForRethrow(Exception rethrow)
        {
#if !SILVERLIGHT
            List<StackTrace> prev;

            // we don't have any dynamic stack trace data, capture the data we can
            // from the raw exception object.
            StackTrace st = new StackTrace(rethrow, true);

            if (!TryGetAssociatedStackTraces(rethrow, out prev))
            {
                prev = new List<StackTrace>();
                AssociateStackTraces(rethrow, prev);
            }

            prev.Add(st);
#endif
            return rethrow;
        }

        /// <summary>
        /// Returns all the stack traces associates with an exception
        /// </summary>
        public static IList<StackTrace> GetExceptionStackTraces(Exception rethrow)
        {
            List<StackTrace> result;
            return TryGetAssociatedStackTraces(rethrow, out result) ? result : null;
        }

        private static void AssociateStackTraces(Exception e, List<StackTrace> traces)
        {
            e.Data[prevStackTraces] = traces;
        }

        private static bool TryGetAssociatedStackTraces(Exception e, out List<StackTrace> traces)
        {
            traces = e.Data[prevStackTraces] as List<StackTrace>;
            return traces != null;
        }
    }

    /// <summary>
    /// A hybrid dictionary which compares based upon object identity.
    /// </summary>
    internal class HybridReferenceDictionary<TKey, TValue> where TKey : class
    {
        private KeyValuePair<TKey, TValue>[] _keysAndValues;
        private Dictionary<TKey, TValue> _dict;
        private int _count;
        private const int _arraySize = 10;

        public HybridReferenceDictionary()
        {
        }

        public HybridReferenceDictionary(int initialCapacity)
        {
            if (initialCapacity > _arraySize)
            {
                _dict = new Dictionary<TKey, TValue>(initialCapacity);
            }
            else
            {
                _keysAndValues = new KeyValuePair<TKey, TValue>[initialCapacity];
            }
        }

        public bool TryGetValue(TKey key, out TValue value)
        {
            Debug.Assert(key != null);

            if (_dict != null)
            {
                return _dict.TryGetValue(key, out value);
            }
            else if (_keysAndValues != null)
            {
                for (int i = 0; i < _keysAndValues.Length; i++)
                {
                    if (_keysAndValues[i].Key == key)
                    {
                        value = _keysAndValues[i].Value;
                        return true;
                    }
                }
            }
            value = default(TValue);
            return false;
        }

        public bool Remove(TKey key)
        {
            Debug.Assert(key != null);

            if (_dict != null)
            {
                return _dict.Remove(key);
            }
            else if (_keysAndValues != null)
            {
                for (int i = 0; i < _keysAndValues.Length; i++)
                {
                    if (_keysAndValues[i].Key == key)
                    {
                        _keysAndValues[i] = new KeyValuePair<TKey, TValue>();
                        _count--;
                        return true;
                    }
                }
            }

            return false;
        }

        public bool ContainsKey(TKey key)
        {
            Debug.Assert(key != null);

            if (_dict != null)
            {
                return _dict.ContainsKey(key);
            }
            else if (_keysAndValues != null)
            {
                for (int i = 0; i < _keysAndValues.Length; i++)
                {
                    if (_keysAndValues[i].Key == key)
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        public int Count
        {
            get
            {
                if (_dict != null)
                {
                    return _dict.Count;
                }
                return _count;
            }
        }

        public IEnumerator<KeyValuePair<TKey, TValue>> GetEnumerator()
        {
            if (_dict != null)
            {
                return _dict.GetEnumerator();
            }

            return GetEnumeratorWorker();
        }

        private IEnumerator<KeyValuePair<TKey, TValue>> GetEnumeratorWorker()
        {
            if (_keysAndValues != null)
            {
                for (int i = 0; i < _keysAndValues.Length; i++)
                {
                    if (_keysAndValues[i].Key != null)
                    {
                        yield return _keysAndValues[i];
                    }
                }
            }
        }

        public TValue this[TKey key]
        {
            get
            {
                Debug.Assert(key != null);

                TValue res;
                if (TryGetValue(key, out res))
                {
                    return res;
                }

                throw new KeyNotFoundException();
            }
            set
            {
                Debug.Assert(key != null);

                if (_dict != null)
                {
                    _dict[key] = value;
                }
                else
                {
                    int index;
                    if (_keysAndValues != null)
                    {
                        index = -1;
                        for (int i = 0; i < _keysAndValues.Length; i++)
                        {
                            if (_keysAndValues[i].Key == key)
                            {
                                _keysAndValues[i] = new KeyValuePair<TKey, TValue>(key, value);
                                return;
                            }
                            else if (_keysAndValues[i].Key == null)
                            {
                                index = i;
                            }
                        }
                    }
                    else
                    {
                        _keysAndValues = new KeyValuePair<TKey, TValue>[_arraySize];
                        index = 0;
                    }

                    if (index != -1)
                    {
                        _count++;
                        _keysAndValues[index] = new KeyValuePair<TKey, TValue>(key, value);
                    }
                    else
                    {
                        _dict = new Dictionary<TKey, TValue>();
                        for (int i = 0; i < _keysAndValues.Length; i++)
                        {
                            _dict[_keysAndValues[i].Key] = _keysAndValues[i].Value;
                        }
                        _keysAndValues = null;

                        _dict[key] = value;
                    }
                }
            }
        }
    }

    /// <summary>
    /// Provides a dictionary-like object used for caches which holds onto a maximum
    /// number of elements specified at construction time.
    ///
    /// This class is not thread safe.
    /// </summary>
    internal class CacheDict<TKey, TValue>
    {
        private readonly Dictionary<TKey, KeyInfo> _dict = new Dictionary<TKey, KeyInfo>();
        private readonly LinkedList<TKey> _list = new LinkedList<TKey>();
        private readonly int _maxSize;

        /// <summary>
        /// Creates a dictionary-like object used for caches.
        /// </summary>
        /// <param name="maxSize">The maximum number of elements to store.</param>
        public CacheDict(int maxSize)
        {
            _maxSize = maxSize;
        }

        /// <summary>
        /// Tries to get the value associated with 'key', returning true if it's found and
        /// false if it's not present.
        /// </summary>
        public bool TryGetValue(TKey key, out TValue value)
        {
            KeyInfo storedValue;
            if (_dict.TryGetValue(key, out storedValue))
            {
                LinkedListNode<TKey> node = storedValue.List;
                if (node.Previous != null)
                {
                    // move us to the head of the list...
                    _list.Remove(node);
                    _list.AddFirst(node);
                }

                value = storedValue.Value;
                return true;
            }

            value = default(TValue);
            return false;
        }

        /// <summary>
        /// Adds a new element to the cache, replacing and moving it to the front if the
        /// element is already present.
        /// </summary>
        public void Add(TKey key, TValue value)
        {
            KeyInfo keyInfo;
            if (_dict.TryGetValue(key, out keyInfo))
            {
                // remove original entry from the linked list
                _list.Remove(keyInfo.List);
            }
            else if (_list.Count == _maxSize)
            {
                // we've reached capacity, remove the last used element...
                LinkedListNode<TKey> node = _list.Last;
                _list.RemoveLast();
                bool res = _dict.Remove(node.Value);
                Debug.Assert(res);
            }

            // add the new entry to the head of the list and into the dictionary
            LinkedListNode<TKey> listNode = new LinkedListNode<TKey>(key);
            _list.AddFirst(listNode);
            _dict[key] = new CacheDict<TKey, TValue>.KeyInfo(value, listNode);
        }

        /// <summary>
        /// Returns the value associated with the given key, or throws KeyNotFoundException
        /// if the key is not present.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1065:DoNotRaiseExceptionsInUnexpectedLocations")]
        public TValue this[TKey key]
        {
            get
            {
                TValue res;
                if (TryGetValue(key, out res))
                {
                    return res;
                }
                throw new KeyNotFoundException();
            }
            set
            {
                Add(key, value);
            }
        }

        private struct KeyInfo
        {
            internal readonly TValue Value;
            internal readonly LinkedListNode<TKey> List;

            internal KeyInfo(TValue value, LinkedListNode<TKey> list)
            {
                Value = value;
                List = list;
            }
        }
    }

    internal class ThreadLocal<T>
    {
        private StorageInfo[] _stores;                                         // array of storage indexed by managed thread ID
        private static readonly StorageInfo[] s_updating = Automation.Utils.EmptyArray<StorageInfo>();   // a marker used when updating the array
        private readonly bool _refCounted;

        public ThreadLocal()
        {
        }

        /// <summary>
        /// True if the caller will guarantee that all cleanup happens as the thread
        /// unwinds.
        ///
        /// This is typically used in a case where the thread local is surrounded by
        /// a try/finally block.  The try block pushes some state, the finally block
        /// restores the previous state.  Therefore when the thread exits the thread
        /// local is back to it's original state.  This allows the ThreadLocal object
        /// to not check the current owning thread on retrieval.
        /// </summary>
        public ThreadLocal(bool refCounted)
        {
            _refCounted = refCounted;
        }

        #region Public API

        /// <summary>
        /// Gets or sets the value for the current thread.
        /// </summary>
        public T Value
        {
            get
            {
                return GetStorageInfo().Value;
            }
            set
            {
                GetStorageInfo().Value = value;
            }
        }

        /// <summary>
        /// Gets the current value if its not == null or calls the provided function
        /// to create a new value.
        /// </summary>
        public T GetOrCreate(Func<T> func)
        {
            Assert.NotNull(func);

            StorageInfo si = GetStorageInfo();
            T res = si.Value;
            if (res == null)
            {
                si.Value = res = func();
            }

            return res;
        }

        /// <summary>
        /// Calls the provided update function with the current value and
        /// replaces the current value with the result of the function.
        /// </summary>
        public T Update(Func<T, T> updater)
        {
            Assert.NotNull(updater);

            StorageInfo si = GetStorageInfo();
            return si.Value = updater(si.Value);
        }

        /// <summary>
        /// Replaces the current value with a new one and returns the old value.
        /// </summary>
        public T Update(T newValue)
        {
            StorageInfo si = GetStorageInfo();
            var oldValue = si.Value;
            si.Value = newValue;
            return oldValue;
        }

        #endregion

        #region Storage implementation

        /// <summary>
        /// Gets the StorageInfo for the current thread.
        /// </summary>
        public StorageInfo GetStorageInfo()
        {
            return GetStorageInfo(_stores);
        }

        private StorageInfo GetStorageInfo(StorageInfo[] curStorage)
        {
            int threadId = Thread.CurrentThread.ManagedThreadId;

            // fast path if we already have a value in the array
            if (curStorage != null && curStorage.Length > threadId)
            {
                StorageInfo res = curStorage[threadId];

                if (res != null && (_refCounted || res.Thread == Thread.CurrentThread))
                {
                    return res;
                }
            }

            return RetryOrCreateStorageInfo(curStorage);
        }

        /// <summary>
        /// Called when the fast path storage lookup fails. if we encountered the Empty storage
        /// during the initial fast check then spin until we hit non-empty storage and try the fast
        /// path again.
        /// </summary>
        private StorageInfo RetryOrCreateStorageInfo(StorageInfo[] curStorage)
        {
            if (curStorage == s_updating)
            {
                // we need to retry
                while ((curStorage = _stores) == s_updating)
                {
                    Thread.Sleep(0);
                }

                // we now have a non-empty storage info to retry with
                return GetStorageInfo(curStorage);
            }

            // we need to mutate the StorageInfo[] array or create a new StorageInfo
            return CreateStorageInfo();
        }

        /// <summary>
        /// Creates the StorageInfo for the thread when one isn't already present.
        /// </summary>
        private StorageInfo CreateStorageInfo()
        {
            // we do our own locking, tell hosts this is a bad time to interrupt us.
            Thread.BeginCriticalRegion();

            StorageInfo[] curStorage = s_updating;
            try
            {
                int threadId = Thread.CurrentThread.ManagedThreadId;
                StorageInfo newInfo = new StorageInfo(Thread.CurrentThread);

                // set to updating while potentially resizing/mutating, then we'll
                // set back to the current value.
                while ((curStorage = Interlocked.Exchange(ref _stores, s_updating)) == s_updating)
                {
                    // another thread is already updating...
                    Thread.Sleep(0);
                }

                // check and make sure we have a space in the array for our value
                if (curStorage == null)
                {
                    curStorage = new StorageInfo[threadId + 1];
                }
                else if (curStorage.Length <= threadId)
                {
                    StorageInfo[] newStorage = new StorageInfo[threadId + 1];
                    for (int i = 0; i < curStorage.Length; i++)
                    {
                        // leave out the threads that have exited
                        if (curStorage[i] != null && curStorage[i].Thread.IsAlive)
                        {
                            newStorage[i] = curStorage[i];
                        }
                    }
                    curStorage = newStorage;
                }

                // create our StorageInfo in the array, the empty check ensures we're only here
                // when we need to create.
                Debug.Assert(curStorage[threadId] == null || curStorage[threadId].Thread != Thread.CurrentThread);

                return curStorage[threadId] = newInfo;
            }
            finally
            {
                if (curStorage != s_updating)
                {
                    // let others access the storage again
                    Interlocked.Exchange(ref _stores, curStorage);
                }

                Thread.EndCriticalRegion();
            }
        }

        /// <summary>
        /// Helper class for storing the value.  We need to track if a ManagedThreadId
        /// has been re-used so we also store the thread which owns the value.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1034:NestedTypesShouldNotBeVisible")] // TODO
        internal sealed class StorageInfo
        {
            internal readonly Thread Thread;                 // the thread that owns the StorageInfo
            public T Value;                                // the current value for the owning thread

            internal StorageInfo(Thread curThread)
            {
                Assert.NotNull(curThread);

                Thread = curThread;
            }
        }

        #endregion
    }

    internal static class Assert
    {
        internal static Exception Unreachable
        {
            get
            {
                Debug.Assert(false, "Unreachable");
                return new InvalidOperationException("Code supposed to be unreachable");
            }
        }

        [Conditional("DEBUG")]
        public static void NotNull(object var)
        {
            Debug.Assert(var != null);
        }

        [Conditional("DEBUG")]
        public static void NotNull(object var1, object var2)
        {
            Debug.Assert(var1 != null && var2 != null);
        }

        [Conditional("DEBUG")]
        public static void NotNull(object var1, object var2, object var3)
        {
            Debug.Assert(var1 != null && var2 != null && var3 != null);
        }

        [Conditional("DEBUG")]
        public static void NotNullItems<T>(IEnumerable<T> items) where T : class
        {
            Debug.Assert(items != null);
            foreach (object item in items)
            {
                Debug.Assert(item != null);
            }
        }

        [Conditional("DEBUG")]
        public static void NotEmpty(string str)
        {
            Debug.Assert(!string.IsNullOrEmpty(str));
        }
    }

    [Flags]
    internal enum ExpressionAccess
    {
        None = 0,
        Read = 1,
        Write = 2,
        ReadWrite = Read | Write,
    }

    internal static class Utils
    {
        internal static Expression Constant(object value)
        {
            return Expression.Constant(value);
        }

        private static readonly DefaultExpression s_voidInstance = Expression.Empty();

        public static DefaultExpression Empty()
        {
            return s_voidInstance;
        }

        public static Expression Void(Expression expression)
        {
            //ContractUtils.RequiresNotNull(expression, "expression");
            if (expression.Type == typeof(void))
            {
                return expression;
            }
            return Expression.Block(expression, Utils.Empty());
        }

        public static DefaultExpression Default(Type type)
        {
            if (type == typeof(void))
            {
                return Empty();
            }
            return Expression.Default(type);
        }

        public static Expression Convert(Expression expression, Type type)
        {
            //ContractUtils.RequiresNotNull(expression, "expression");

            if (expression.Type == type)
            {
                return expression;
            }

            if (expression.Type == typeof(void))
            {
                return Expression.Block(expression, Utils.Default(type));
            }

            if (type == typeof(void))
            {
                return Void(expression);
            }

            // TODO: this is not the right level for this to be at. It should
            // be pushed into languages if they really want this behavior.
            if (type == typeof(object))
            {
                return Box(expression);
            }

            return Expression.Convert(expression, type);
        }

        public static Expression Box(Expression expression)
        {
            MethodInfo m;
            if (expression.Type == typeof(int))
            {
                m = ScriptingRuntimeHelpers.Int32ToObjectMethod;
            }
            else if (expression.Type == typeof(bool))
            {
                m = ScriptingRuntimeHelpers.BooleanToObjectMethod;
            }
            else
            {
                m = null;
            }

            return Expression.Convert(expression, typeof(object), m);
        }

        public static bool IsReadWriteAssignment(this ExpressionType type)
        {
            switch (type)
            {
                // unary:
                case ExpressionType.PostDecrementAssign:
                case ExpressionType.PostIncrementAssign:
                case ExpressionType.PreDecrementAssign:
                case ExpressionType.PreIncrementAssign:

                // binary - compound:
                case ExpressionType.AddAssign:
                case ExpressionType.AddAssignChecked:
                case ExpressionType.AndAssign:
                case ExpressionType.DivideAssign:
                case ExpressionType.ExclusiveOrAssign:
                case ExpressionType.LeftShiftAssign:
                case ExpressionType.ModuloAssign:
                case ExpressionType.MultiplyAssign:
                case ExpressionType.MultiplyAssignChecked:
                case ExpressionType.OrAssign:
                case ExpressionType.PowerAssign:
                case ExpressionType.RightShiftAssign:
                case ExpressionType.SubtractAssign:
                case ExpressionType.SubtractAssignChecked:
                    return true;
            }
            return false;
        }
    }

    internal static class CollectionExtension
    {
        internal static bool TrueForAll<T>(this IEnumerable<T> collection, Predicate<T> predicate)
        {
            //ContractUtils.RequiresNotNull(collection, "collection");
            //ContractUtils.RequiresNotNull(predicate, "predicate");

            foreach (T item in collection)
            {
                if (!predicate(item)) return false;
            }

            return true;
        }

        internal static U[] Map<T, U>(this ICollection<T> collection, Func<T, U> select)
        {
            int count = collection.Count;
            U[] result = new U[count];
            count = 0;
            foreach (T t in collection)
            {
                result[count++] = select(t);
            }
            return result;
        }

        // We could probably improve the hashing here
        internal static int ListHashCode<T>(this IEnumerable<T> list)
        {
            var cmp = EqualityComparer<T>.Default;
            int h = 6551;
            foreach (T t in list)
            {
                h ^= (h << 5) ^ cmp.GetHashCode(t);
            }
            return h;
        }

        internal static bool ListEquals<T>(this ICollection<T> first, ICollection<T> second)
        {
            if (first.Count != second.Count)
            {
                return false;
            }
            var cmp = EqualityComparer<T>.Default;
            var f = first.GetEnumerator();
            var s = second.GetEnumerator();
            while (f.MoveNext())
            {
                s.MoveNext();

                if (!cmp.Equals(f.Current, s.Current))
                {
                    return false;
                }
            }
            return true;
        }
    }

    internal sealed class ListEqualityComparer<T> : EqualityComparer<ICollection<T>>
    {
        internal static readonly ListEqualityComparer<T> Instance = new ListEqualityComparer<T>();

        private ListEqualityComparer() { }

        // EqualityComparer<T> handles null and object identity for us
        public override bool Equals(ICollection<T> x, ICollection<T> y)
        {
            return x.ListEquals(y);
        }

        public override int GetHashCode(ICollection<T> obj)
        {
            return obj.ListHashCode();
        }
    }
}
