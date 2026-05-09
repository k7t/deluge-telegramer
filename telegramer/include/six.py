"""Minimal six stub for Python 3 — replaces the six compatibility library."""

import sys

PY2 = False
PY3 = True

string_types = (str,)
text_type = str
binary_type = bytes
integer_types = (int,)
class_types = (type,)

def iteritems(d):
    return d.items()

def itervalues(d):
    return d.values()

def iterkeys(d):
    return d.keys()

def raise_from(value, from_value):
    try:
        raise value from from_value
    finally:
        value = None

def with_metaclass(meta, *bases):
    class metaclass(type):
        def __new__(cls, name, this_bases, d):
            return meta(name, bases, d)
        __init__ = type.__init__
    return type.__new__(metaclass, 'temporary_class', (), {})

def add_metaclass(metaclass):
    def wrapper(cls):
        orig_vars = cls.__dict__.copy()
        slots = orig_vars.get('__slots__')
        if slots is not None:
            if isinstance(slots, str):
                slots = [slots]
            for slots_var in slots:
                orig_vars.pop(slots_var)
        orig_vars.pop('__dict__', None)
        orig_vars.pop('__weakref__', None)
        return metaclass(cls.__name__, cls.__bases__, orig_vars)
    return wrapper

moves = type(sys)('six.moves')
moves.range = range
moves.map = map
moves.filter = filter
moves.zip = zip
moves.input = input
sys.modules['six.moves'] = moves
