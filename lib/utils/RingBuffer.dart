import 'package:flutter/cupertino.dart';

class RingBuffer<T> extends ChangeNotifier with Iterable<T> {
  final List<T?> _buffer;
  int _writeIndex = 0;
  int _readIndex = 0;
  int _size = 0;

  RingBuffer(int capacity)
      : assert(capacity > 0),
        _buffer = List<T?>.filled(capacity, null);

  int get capacity => _buffer.length;

  @override
  int get length => _size;

  bool get isFull => _size == capacity;

  void add(T value) {
    _buffer[_writeIndex] = value;
    _writeIndex = (_writeIndex + 1) % capacity;
    if (isFull) {
      _readIndex =
          (_readIndex + 1) % capacity; // When buffer is full, move read index
    } else {
      _size++;
    }
    notifyListeners();
  }

  T? get() {
    if (_size == 0) return null;
    final value = _buffer[_readIndex];
    _buffer[_readIndex] = null; // Optional: Clear the value after getting it
    _readIndex = (_readIndex + 1) % capacity;
    _size--;
    return value;
  }

  @override
  Iterator<T> get iterator =>
      _RingBufferIterator<T>(_buffer, _readIndex, _size, capacity);

  Iterator<T> get reversed =>
      _ReverseRingBufferIterator(_buffer, _readIndex, _size, capacity);

  @override
  String toString() {
    return _buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RingBuffer &&
          runtimeType == other.runtimeType &&
          _writeIndex == other._writeIndex;

  @override
  int get hashCode => _writeIndex.hashCode;
}

class _RingBufferIterator<T> implements Iterator<T> {
  final List<T?> _buffer;
  final int _start;
  final int _size;
  final int _capacity;
  int _currentIndex;
  int _count = 0;
  T? _current;

  _RingBufferIterator(this._buffer, this._start, this._size, this._capacity)
      : _currentIndex = _start;

  @override
  T get current => _current as T;

  @override
  bool moveNext() {
    if (_count >= _size) return false;
    _current = _buffer[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _capacity;
    _count++;
    return true;
  }
}

class _ReverseRingBufferIterator<T> implements Iterator<T> {
  final List<T?> _buffer;
  final int _start;
  final int _size;
  final int _capacity;
  int _currentIndex;
  int _count = 0;
  T? _current;

  _ReverseRingBufferIterator(
      this._buffer, this._start, this._size, this._capacity)
      : _currentIndex = (_start + _size - 1) % _capacity;

  @override
  T get current => _current as T;

  @override
  bool moveNext() {
    if (_count >= _size) return false;
    _current = _buffer[_currentIndex];
    _currentIndex = (_currentIndex - 1 + _capacity) % _capacity; // 역방향으로 이동
    _count++;
    return true;
  }
}
