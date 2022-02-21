package echo.util;

@:using(echo.util.Disposable)
interface IDisposable {
  function dispose():Void;
}
/**
 * Checks if an object is not null before calling dispose(), always returns null.
 *
 * @param	object	An IDisposable object that will be disposed if it's not null.
 * @return	null
 */
inline function dispose<T:IDisposable>(object:Null<IDisposable>):T {
  if (object != null) {
    object.dispose();
  }
  return null;
}
/**
 * dispose every element of an array of IDisposables
 *
 * @param	array	An Array of IDisposable objects
 * @return	null
 */
inline function disposeArray<T:IDisposable>(array:Array<T>):Array<T> {
  if (array != null) {
    for (e in array) dispose(e);
    array.splice(0, array.length);
  }
  return null;
}
