/******************************************************
 *
 * BucketArray<T>
 *
 * A linear data structure that can grow dynamically
 *
 ******************************************************/

typealias BucketLocator = (bucket: U64, index: U64)

/*= BEGIN_REFSTRUCT =*/
struct BucketArray<T> {
    var zone : MemoryZoneRef /*= GETSET =*/
    
    var first : BucketRef<T> /*= GETSET =*/
    var last : BucketRef<T> /*= GETSET =*/
    var capacity : U64 /*= GETSET =*/
    var used : U64 /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

/*= BEGIN_REFSTRUCT =*/
struct Bucket<T> {
    // A bucket is always 64 elements wide
    var storage : Ptr<T> /*= GETSET =*/
    var used : U64 /*= GETSET =*/
    var occupiedMask : U64 /*= GETSET =*/
    var next : BucketRef<T> /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

extension BucketArrayRef {
    subscript(locator: BucketLocator) -> Ptr<T>? {
        get {
            assert(locator.index < 64)
            assert((locator.bucket * 64) + locator.index < self.capacity)
            
            var bucket = self.first
            for _ in 0..<locator.bucket {
                bucket = bucket.next
            }
            if ((bucket.occupiedMask >> locator.index) & 0x1) == 0 {
                // Empty slot
                return nil
            }
            return bucket.storage + Int(locator.index)
        }
    }
}

func createBucketArray<T>(_ zone: MemoryZoneRef, _ type : T.Type, _ capacity : U64) -> BucketArrayRef<T> {
    /*= TIMED_BLOCK =*/ TIMED_BLOCK_BEGIN(0); defer { TIMED_BLOCK_END(0) };
    // Allocate space for the BucketArray and Buckets up front (to put them close together)
    let bucketArrayPtr = allocateTypeFromZone(zone, BucketArray<T>.self)
    let bucketArray = BucketArrayRef<T>(bucketArrayPtr)
    bucketArray.zone = zone
    bucketArray.capacity = ((capacity + 63) / 64) * 64 // Round up to next multiple of 64
    bucketArray.used = 0
    
    var numBuckets = capacity / 64
    if capacity % 64 != 0 {
        numBuckets += 1
    }
    var buckets = [BucketRef<T>]()
    for _ in 0..<numBuckets {
        let bucketPtr = allocateTypeFromZone(zone, Bucket<T>.self)
        let bucket = BucketRef<T>(bucketPtr)
        bucket.used = 0
        bucket.occupiedMask = 0
        buckets.append(bucket)
    }
    
    // Then allocate all the space for the elements in one giant block
    let bucketSize = MemoryLayout<T>.stride * 64
    let totalBytes = bucketSize * Int(numBuckets)
    let storagePtr = allocateFromZone(zone, totalBytes).bindMemory(to: T.self, capacity: Int(capacity))
    
    for i in 0..<numBuckets {
        let bucket = buckets[Int(i)]
        bucket.storage = storagePtr + Int(i * 64)
        if i != numBuckets - 1 {
            bucket.next = buckets[Int(i) + 1]
        }
    }
    
    bucketArray.first = buckets[0]
    bucketArray.last = buckets[Int(numBuckets - 1)]
    
    return bucketArray
}

func bucketArrayNewElement<T>(_ bucketArray: BucketArrayRef<T>) -> (Ptr<T>, BucketLocator) {
    // NOTE: There's no guarantee the returned reference points to zeroed memory
    if bucketArray.used == bucketArray.capacity {
        bucketArrayAddBucket(bucketArray)
    }
    
    var bucket = bucketArray.first
    var totalBuckets = bucketArray.capacity / 64
    if bucketArray.capacity % 64 != 0 {
        totalBuckets += 1
    }
    
    var bucketIndex : U64 = 0
    // NOTE: Since we already added a new bucket in the case of the array being full,
    //       this while loop is guaranteed to find a bucket with empty slots
    while bucket.occupiedMask == U64.max {
        bucket = bucket.next
        bucketIndex += 1
    }
    
    var index : U64 = 0
    while ((bucket.occupiedMask >> index) & 0x1) == 0x1 {
        index += 1
    }
    
    let locator : BucketLocator = (bucketIndex, index)
    
    let newElementPtr = bucket.storage + Int(index)
    
    bucket.occupiedMask |= (0x1 << index)
    bucket.used += 1
    bucketArray.used += 1
    
    return (newElementPtr, locator)
}

func bucketArrayAddBucket<T>(_ bucketArray: BucketArrayRef<T>) {
    let newBucketPtr = allocateTypeFromZone(bucketArray.zone, Bucket<T>.self)
    let newBucket = BucketRef<T>(newBucketPtr)
    newBucket.used = 0
    newBucket.occupiedMask = 0
    
    let bucketSize = MemoryLayout<T>.stride * 64
    let newBucketStoragePtr = allocateFromZone(bucketArray.zone, bucketSize).bindMemory(to: T.self, capacity: 64)
    newBucket.storage = newBucketStoragePtr
    
    let lastBucket = bucketArray.last
    lastBucket.next = newBucket
    bucketArray.last = newBucket
    bucketArray.capacity += 64
}

func bucketArrayRemove<T>(_ bucketArray: BucketArrayRef<T>, _ locator: BucketLocator) {
    assert(locator.index < 64)
    assert((locator.bucket * 64) + locator.index < bucketArray.capacity)
    
    var bucket = bucketArray.first
    for _ in 0..<locator.bucket {
        bucket = bucket.next
    }
    
    assert((bucket.occupiedMask >> locator.index) & 0x1 == 0x1)
    
    // Simply mark the slot as unoccupied
    bucket.occupiedMask ^= 0x1 << locator.index
    
    bucket.used -= 1
    bucketArray.used -= 1
}

func bucketArrayClear<T>(_ bucketArray: BucketArrayRef<T>) {
    // This simply resets the used and occupiedMask values
    // I.e., the actual memory is not zeroed out
    
    var numBuckets = bucketArray.capacity / 64
    if bucketArray.capacity % 64 != 0 {
        numBuckets += 1
    }
    
    var bucket = bucketArray.first
    for i in 0..<numBuckets {
        bucket.used = 0
        bucket.occupiedMask = 0
        if i != numBuckets - 1 {
            bucket = bucket.next
        }
    }
    
    bucketArray.used = 0
}

struct BucketArrayIterator<T> : IteratorProtocol {
    let bucketArray : BucketArrayRef<T>
    var currentBucket : BucketRef<T>
    var index : U64 = 0
    var numFound : U64 = 0
    
    init(_ newBucketArray: BucketArrayRef<T>) {
        bucketArray = newBucketArray
        currentBucket = bucketArray.first
    }
    
    mutating func next() -> Ptr<T>? {
        if numFound == bucketArray.used {
            return nil
        }
        while (currentBucket.occupiedMask & (0x1 << index)) == 0 {
            index += 1
            if index == 64 {
                currentBucket = currentBucket.next
                index = 0
            }
        }
        
        let result = currentBucket.storage + Int(index)
        
        numFound += 1
        index += 1
        if index == 64 {
            currentBucket = currentBucket.next
            index = 0
        }
        return result
    }
}

extension BucketArrayRef : Sequence {
    func makeIterator() -> BucketArrayIterator<T> {
        return BucketArrayIterator<T>(self)
    }
}






















