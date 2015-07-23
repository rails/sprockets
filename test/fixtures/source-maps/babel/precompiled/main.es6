
var odds = evens.map(v => v + 1);
var nums = evens.map((v, i) => v + i);

class SkinnedMesh extends THREE.Mesh {
  constructor(geometry, materials) {
    super(geometry, materials);

  }
  update(camera) {
    super.update();
  }
  static defaultMatrix() {
    return new THREE.Matrix4();
  }
}

var fibonacci = {
  [Symbol.iterator]: function*() {
    var pre = 0, cur = 1;
    for (;;) {
      var temp = pre;
      pre = cur;
      cur += temp;
      yield cur;
    }
  }
}
