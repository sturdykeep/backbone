import 'dart:collection';

/// A pool of objects that can be reused.
class Pool<T> {
  final HashSet<T> _pool = HashSet<T>();
  final T Function() _creator;
  final void Function(T) _resetter;

  /// Creates a pool of objects that can be reused.
  ///
  /// [creator] is a function that creates a new instance of the object.
  /// [resetter] is a function that resets the object to its initial state.
  Pool(this._creator, this._resetter);

  /// Gets an object from the pool.
  ///
  /// If the pool is empty, a new object is created.
  T get() {
    if (_pool.isEmpty) {
      return _creator();
    } else {
      final first = _pool.first;
      _pool.remove(first);
      return first;
    }
  }

  /// Returns an object to the pool.
  ///
  /// The object is reset to its initial state.
  /// If the object is already in the pool, it is not added again.
  /// Returns true if the object was added to the pool.
  /// Returns false if the object was already in the pool.
  bool release(T obj) {
    _resetter(obj);
    return _pool.add(obj);
  }

  /// Check if the pool contains the object.
  /// Returns true if the object is in the pool.
  /// Returns false if the object is not in the pool.
  bool contains(T obj) => _pool.contains(obj);

  /// Returns the number of objects in the pool.
  int get size => _pool.length;
}