// This class was created to prevent a frameBuffer read by Flutter from being
// concurrently modified by a write method (mpv's renderer).
//
// To do this, two pools are set up, one for frameBuffers available for writing,
// the other for frameBuffers ready to be read by Flutter.
//
// When a frameBuffer has finished being modified and is "pushed", the oldest
// ready frameBuffer is marked as the current frameBuffer, and the oldest
// current frameBuffer is placed in the pool of frameBuffers available for
// writing — or, with a non-zero recycleDelay, held in quarantine for that many
// pushAsReady cycles first, because Flutter may still be compositing the
// buffer it received from copyPixelBuffer for a frame or more after it stopped
// being the current one.
//
// The use of at least three frameBuffers ensures that the read and write phases
// do not overlap, thus eliminating flicker.
public class SwappableObjectManager<T> {
  private let lock: NSRecursiveLock = NSRecursiveLock()
  private var available: [T]
  private var ready: [T] = []
  private var quarantined: [(object: T, remaining: Int)] = []
  private var _current: T?
  private let recycleDelay: Int

  init(objects: [T], skipCheckArgs: Bool = false, recycleDelay: Int = 0) {
    if !skipCheckArgs {
      SwappableObjectManager.checkArgs(objects)
    }

    available = objects
    self.recycleDelay = recycleDelay
  }

  public func reinit(objects: [T], skipCheckArgs: Bool = false) {
    if !skipCheckArgs {
      SwappableObjectManager.checkArgs(objects)
    }

    lock.lock()
    defer {
      lock.unlock()
    }

    available = objects
    ready = []
    quarantined = []
    _current = nil
  }

  public func nextAvailable() -> T? {
    lock.lock()
    defer {
      lock.unlock()
    }

    let object: T? =
      available.count > 0
      ? available.removeFirst()
      : nil

    return object
  }

  public func pushAsReady(_ object: T) {
    lock.lock()
    defer {
      lock.unlock()
    }

    ready.append(object)
    recycleQuarantined()
    updateCurrent()
  }

  public var current: T? {
    lock.lock()
    defer {
      lock.unlock()
    }

    return _current
  }

  private func recycleQuarantined() {
    lock.lock()
    defer {
      lock.unlock()
    }

    guard recycleDelay > 0 else {
      return
    }

    for index in quarantined.indices.reversed() {
      let entry = quarantined[index]
      if entry.remaining <= 1 {
        quarantined.remove(at: index)
        available.append(entry.object)
      } else {
        quarantined[index] = (object: entry.object, remaining: entry.remaining - 1)
      }
    }
  }

  private func updateCurrent() {
    lock.lock()
    defer {
      lock.unlock()
    }

    let next: T? =
      ready.count > 0
      ? ready.removeFirst()
      : nil

    if next == nil {
      return
    }

    let old: T? = _current
    _current = next

    if old == nil {
      return
    }

    if recycleDelay > 0 {
      quarantined.append((object: old!, remaining: recycleDelay))
    } else {
      available.append(old!)
    }
  }

  static private func checkArgs(_ objects: [T]) {
    if objects.count < 2 {
      NSLog("SwappableObjectManager: require at least two objects to work")
    }
  }
}
