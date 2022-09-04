/// TODO Document me
class MultiIterableView<I> extends Iterable<I> {
  final List<Iterable<I>> iterables;

  MultiIterableView(this.iterables);

  @override
  Iterator<I> get iterator => MultiIterableViewIterator<I>(iterables);
}

/// TODO Document me
class MultiIterableViewIterator<I> implements Iterator<I> {
  final List<Iterable<I>> iterables;

  MultiIterableViewIterator(this.iterables) {
    if (iterables.isEmpty) {
      iterables.add([]);
    }
    _iterators = iterables.map((iterable) => iterable.iterator).toList();
    _currentIterator = _iterators.first;
  }

  // Internal state
  List<Iterator<I>> _iterators = [];
  int _currentIteratorIndex = 0;
  late Iterator<I> _currentIterator;

  int get totalLength =>
      iterables.fold(0, (sum, iterable) => sum + iterable.length);

  @override
  I get current => _currentIterator.current;

  @override
  bool moveNext() {
    if (_currentIterator.moveNext()) {
      return true;
    } else {
      if (_currentIteratorIndex < _iterators.length - 1) {
        _currentIteratorIndex++;
        _currentIterator = _iterators[_currentIteratorIndex];
        return moveNext();
      } else {
        return false;
      }
    }
  }
}
