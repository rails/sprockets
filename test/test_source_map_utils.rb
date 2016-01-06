require 'minitest/autorun'
require 'sprockets/source_map_utils'

class TestSourceMapUtils < MiniTest::Test

  def test_map
    source_map = {
      'version'  => 3,
      'file'     => "script.min.js",
      'mappings' => "AAEAA,QAASA,MAAK,EAAG,CACfC,OAAAC,IAAA,CAAY,eAAZ,CADe",
      'sources'  => ["script.js"],
      'names'    => ["hello", "console", "log"]
    }
    mappings = Sprockets::SourceMapUtils.decode_vlq_mappings(source_map['mappings'], sources: source_map['sources'], names: source_map['names'])

    assert mapping = mappings.first
    assert_equal 1,           mapping[:generated].first
    assert_equal 0,           mapping[:generated].last
    assert_equal 3,           mapping[:original].first
    assert_equal 0,           mapping[:original].last
    assert_equal 'script.js', mapping[:source]
    assert_equal 'hello',     mapping[:name]

    assert mapping = mappings.last
    assert_equal 1,           mapping[:generated].first
    assert_equal 45,          mapping[:generated].last
    assert_equal 3,           mapping[:original].first
    assert_equal 17,          mapping[:original].last
    assert_equal 'script.js', mapping[:source]
    assert_equal nil,         mapping[:name]

    expected = JSON.generate(source_map)
    actual   = Sprockets::SourceMapUtils.encode_json_source_map(mappings, filename: "script.min.js")
    assert_equal expected, actual
  end

  def test_map2
    source_map = {
      'version'  => 3,
      'file'     => "example.js",
      'mappings' => ";;;;;EACAA;;EACAC;;EAGA;IAAA;;;EAGAC;IAAS;;;EAGTC;;EAGAC;IACE;IACA;IACA;MAAQ;;;;EAGVC;;;IACE;;;EAGF;IAAA;;;EAGAC;;;IAAQ;;MAAA",
      'sources'  => ["example.coffee"],
      'names'    => ["number", "opposite", "square", "list", "math", "race", "cubes"]
    }

    mappings = Sprockets::SourceMapUtils.decode_vlq_mappings(source_map['mappings'], sources: source_map['sources'], names: source_map['names'])

    assert mapping = mappings.first
    assert_equal 6,                mapping[:generated].first
    assert_equal 2,                mapping[:generated].last
    assert_equal 2,                mapping[:original].first
    assert_equal 0,                mapping[:original].last
    assert_equal 'example.coffee', mapping[:source]
    assert_equal 'number',         mapping[:name]

    assert mapping = mappings.last
    assert_equal 43,               mapping[:generated].first
    assert_equal 6,                mapping[:generated].last
    assert_equal 28,               mapping[:original].first
    assert_equal 8,                mapping[:original].last
    assert_equal 'example.coffee', mapping[:source]
    assert_equal nil,              mapping[:name]

    expected = JSON.generate(source_map)
    actual   = Sprockets::SourceMapUtils.encode_json_source_map(mappings, filename: "example.js")
    assert_equal expected, actual
  end

  def test_map3
    source_map = {
      'version'  => 3,
      'file'     => "example.min.js",
      'mappings' => "AACC,SAAQ,EAAG,CAAA,IACCA,CADD,CACOC,CADP,CACaC,CADb,CAC0CC,CAWpDA,EAAA,CAASA,QAAQ,CAACC,CAAD,CAAI,CACnB,MAAOA,EAAP,CAAWA,CADQ,CAIrBJ,EAAA,CAAO,CAAC,CAAD,CAAI,CAAJ,CAAO,CAAP,CAAU,CAAV,CAAa,CAAb,CAEPC,EAAA,CAAO,MACCI,IAAAC,KADD,QAEGH,CAFH,MAGCI,QAAQ,CAACH,CAAD,CAAI,CAChB,MAAOA,EAAP,CAAWD,CAAA,CAAOC,CAAP,CADK,CAHb,CAcc,YAArB,GAAI,MAAOI,MAAX,EAA8C,IAA9C,GAAoCA,KAApC,EACEC,KAAA,CAAM,YAAN,CAGO,UAAQ,EAAG,CAAA,IACdC,CADc,CACVC,CADU,CACJC,CACdA,EAAA,CAAW,EACNF,EAAA,CAAK,CAAV,KAAaC,CAAb,CAAoBX,CAAAa,OAApB,CAAiCH,CAAjC,CAAsCC,CAAtC,CAA4CD,CAAA,EAA5C,CACER,CACA,CADMF,CAAA,CAAKU,CAAL,CACN,CAAAE,CAAAE,KAAA,CAAcb,CAAAM,KAAA,CAAUL,CAAV,CAAd,CAEF,OAAOU,EAPW,CAAX,CAAA,EApCC,CAAX,CAAAG,KAAA,CA8CO,IA9CP",
      'sources'  => ["example.js"],
      'names'    => ["list","math","num","square","x","Math","sqrt","cube","elvis","alert","_i","_len","_results","length","push","call"]
    }

    mappings = Sprockets::SourceMapUtils.decode_vlq_mappings(source_map['mappings'], sources: source_map['sources'], names: source_map['names'])

    assert mapping = mappings.first
    assert_equal 1,            mapping[:generated].first
    assert_equal 0,            mapping[:generated].last
    assert_equal 2,            mapping[:original].first
    assert_equal 1,            mapping[:original].last
    assert_equal 'example.js', mapping[:source]
    assert_equal nil,          mapping[:name]

    assert mapping = mappings.last
    assert_equal 1,            mapping[:generated].first
    assert_equal 289,          mapping[:generated].last
    assert_equal 2,            mapping[:original].first
    assert_equal 1,            mapping[:original].last
    assert_equal 'example.js', mapping[:source]
    assert_equal nil,          mapping[:name]

    expected = JSON.generate(source_map)
    actual   = Sprockets::SourceMapUtils.encode_json_source_map(mappings, filename: "example.min.js")
    assert_equal expected, actual
  end

  def test_concat_empty_source_map_returns_original
    abc_mappings = [
      { source: 'a.js', generated: [rand(1..100), rand(0..100)], original: [rand(1..100), rand(0..100)] },
      { source: 'b.js', generated: [rand(1..100), rand(0..100)], original: [rand(1..100), rand(0..100)] },
      { source: 'c.js', generated: [rand(1..100), rand(0..100)], original: [rand(1..100), rand(0..100)] }
    ].freeze

    assert_equal abc_mappings, Sprockets::SourceMapUtils.concat_source_maps(nil, abc_mappings)
    assert_equal abc_mappings, Sprockets::SourceMapUtils.concat_source_maps(abc_mappings, nil)

    assert_equal abc_mappings, Sprockets::SourceMapUtils.concat_source_maps([], abc_mappings)
    assert_equal abc_mappings, Sprockets::SourceMapUtils.concat_source_maps(abc_mappings, [])
  end

  def test_concat_source_maps
    abc_mappings = [
      { source: 'a.js', generated: [1, 0], original: [1,  0] },
      { source: 'b.js', generated: [2, 0], original: [20, 0] },
      { source: 'c.js', generated: [3, 0], original: [30, 0] }
    ].freeze

    d_mapping = [
      { source: 'd.js', generated: [1, 0], original: [1, 0] }
    ].freeze

    assert_equal [
      { source: 'a.js', generated: [1, 0], original: [1,  0] },
      { source: 'b.js', generated: [2, 0], original: [20, 0] },
      { source: 'c.js', generated: [3, 0], original: [30, 0] },
      { source: 'd.js', generated: [4, 0], original: [1,  0] }
    ], Sprockets::SourceMapUtils.concat_source_maps(abc_mappings, d_mapping)

    assert_equal [
      { source: 'd.js', generated: [1, 0], original: [1,  0] },
      { source: 'a.js', generated: [2, 0], original: [1,  0] },
      { source: 'b.js', generated: [3, 0], original: [20, 0] },
      { source: 'c.js', generated: [4, 0], original: [30, 0] }
    ], Sprockets::SourceMapUtils.concat_source_maps(d_mapping, abc_mappings)
  end

  def test_combine_source_maps_returns_original
    abc_mappings = [
      { source: 'a.js', generated: [1, 0], original: [0,  0] },
      { source: 'b.js', generated: [2, 0], original: [20, 0] },
      { source: 'c.js', generated: [3, 0], original: [30, 0] }
    ]
    assert_equal abc_mappings, Sprockets::SourceMapUtils.combine_source_maps([], abc_mappings)
    assert_equal abc_mappings, Sprockets::SourceMapUtils.combine_source_maps(nil, abc_mappings)
  end

  def test_combine_source_maps
    first_mapping =[
     { :source => "index.coffee", :generated => [2,   0], :original => [1,  0] },
     { :source => "index.coffee", :generated => [3,   0], :original => [1,  0] },
     { :source => "index.coffee", :generated => [3,   6], :original => [1,  0] },
     { :source => "index.coffee", :generated => [3,  10], :original => [1,  0] },
     { :source => "index.coffee", :generated => [5,   0], :original => [1,  0] },
     { :source => "index.coffee", :generated => [5,   2], :original => [1,  0] },
     { :source => "index.coffee", :generated => [5,   6], :original => [1,  0] },
     { :source => "index.coffee", :generated => [5,   9], :original => [1,  7] },
     { :source => "index.coffee", :generated => [5,  18], :original => [1,  7] },
     { :source => "index.coffee", :generated => [5,  21], :original => [1,  7] },
     { :source => "index.coffee", :generated => [6,  11], :original => [2,  2] },
     { :source => "index.coffee", :generated => [6,  16], :original => [2,  2] },
     { :source => "index.coffee", :generated => [6,  17], :original => [2,  8] },
     { :source => "index.coffee", :generated => [6,  30], :original => [2,  2] },
     { :source => "index.coffee", :generated => [6,  32], :original => [1,  7] },
     { :source => "index.coffee", :generated => [7,   2], :original => [1,  7] },
     { :source => "index.coffee", :generated => [7,   3], :original => [1,  0] },
     { :source => "index.coffee", :generated => [7,   4], :original => [1,  0] },
     { :source => "index.coffee", :generated => [9,   0], :original => [4,  0] },
     { :source => "index.coffee", :generated => [9,   2], :original => [4,  0] },
     { :source => "index.coffee", :generated => [9,   6], :original => [4, 11] },
     { :source => "index.coffee", :generated => [9,  10], :original => [4,  0] },
     { :source => "index.coffee", :generated => [10,  0], :original => [4,  0] },
     { :source => "index.coffee", :generated => [10,  4], :original => [4,  3] },
     { :source => "index.coffee", :generated => [10,  8], :original => [4,  0] },
     { :source => "index.coffee", :generated => [10,  9], :original => [4,  0] },
     { :source => "index.coffee", :generated => [10, 10], :original => [4,  0] },
     { :source => "index.coffee", :generated => [10, 11], :original => [4,  0] },
     { :source => "index.coffee", :generated => [11,  3], :original => [1,  0] },
     { :source => "index.coffee", :generated => [12,  0], :original => [1,  0] }
   ]

    second_mapping = [
      { :source => "index.js", :generated => [1,  1], :original => [2,  0] },
      { :source => "index.js", :generated => [1, 12], :original => [3,  2] },
      { :source => "index.js", :generated => [1, 15], :original => [3,  6], :name => "test" },
      { :source => "index.js", :generated => [1, 20], :original => [5,  2], :name => "test" },
      { :source => "index.js", :generated => [1, 26], :original => [5,  9] },
      { :source => "index.js", :generated => [1, 37], :original => [6,  4] },
      { :source => "index.js", :generated => [1, 43], :original => [6, 11], :name => "alert" },
      { :source => "index.js", :generated => [1, 50], :original => [6, 17] },
      { :source => "index.js", :generated => [1, 65], :original => [9,  2] },
      { :source => "index.js", :generated => [1, 69], :original => [9,  6] },
      { :source => "index.js", :generated => [1, 74], :original => [9, 12] },
      { :source => "index.js", :generated => [1, 75], :original => [10, 4], :name => "test" },
      { :source => "index.js", :generated => [1, 84], :original => [13, 3], :name => "call" },
      { :source => "index.js", :generated => [1, 89], :original => [13, 8], :name => "this" }
    ]

    expected = [
      { :source => "index.coffee", :generated => [1,  1], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 12], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 15], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 20], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 26], :original => [1,  7]},
      { :source => "index.coffee", :generated => [1, 37], :original => [1,  7]},
      { :source => "index.coffee", :generated => [1, 43], :original => [2,  2]},
      { :source => "index.coffee", :generated => [1, 50], :original => [2,  8]},
      { :source => "index.coffee", :generated => [1, 65], :original => [4,  0]},
      { :source => "index.coffee", :generated => [1, 69], :original => [4, 11]},
      { :source => "index.coffee", :generated => [1, 74], :original => [4,  0]},
      { :source => "index.coffee", :generated => [1, 75], :original => [4,  3]},
      { :source => "index.coffee", :generated => [1, 84], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 89], :original => [1,  0]}
    ]

    combined_mappings = Sprockets::SourceMapUtils.combine_source_maps(first_mapping, second_mapping)
    assert_equal expected, combined_mappings

    assert_equal 'CAAA,WAAA,GAAA,KAAA,MAAO,WAAA,MACL,OAAM,eAER,IAAW,KAAX,CAAG,SAHH,KAAA',
      Sprockets::SourceMapUtils.encode_vlq_mappings(combined_mappings)
  end

  def test_combine_source_maps_skips_default
    first_mapping = [
      { :source => "index.coffee", :generated => [1,  0], :original => [1,  0]},
    ]
    second_mapping = [
      { :source => "index.coffee", :generated => [1,  1], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 12], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 15], :original => [1,  0]},
      { :source => "index.coffee", :generated => [1, 20], :original => [1,  0]},
    ]

    combined_mappings = Sprockets::SourceMapUtils.combine_source_maps(first_mapping, second_mapping)
    assert_equal second_mapping, combined_mappings
  end

  def test_compare_offsets
    assert_equal( 0,  Sprockets::SourceMapUtils.compare_source_offsets([1, 5], [1, 5]))
    assert_equal(-1,  Sprockets::SourceMapUtils.compare_source_offsets([1, 5], [2, 0]))
    assert_equal(-1,  Sprockets::SourceMapUtils.compare_source_offsets([1, 5], [1, 6]))
    assert_equal(-1,  Sprockets::SourceMapUtils.compare_source_offsets([1, 5], [5, 6]))
    assert_equal( 1,  Sprockets::SourceMapUtils.compare_source_offsets([1, 5], [1, 4]))
    assert_equal( 1,  Sprockets::SourceMapUtils.compare_source_offsets([2, 0], [1, 4]))
    assert_equal( 1,  Sprockets::SourceMapUtils.compare_source_offsets([5, 0], [1, 4]))
  end

  def test_bsearch_mappings
    mappings = [
      { source: 'a.js', generated: [1, 0], original: [1,  0] },
      { source: 'b.js', generated: [2, 0], original: [20, 0] },
      { source: 'c.js', generated: [3, 0], original: [30, 0] },
      { source: 'f.js', generated: [5, 0], original: [40, 0] },
    ]

    assert_equal [1,  0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [1, 0])[:original]
    assert_equal [1,  0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [1, 5])[:original]
    assert_equal [20, 0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [2, 0])[:original]
    assert_equal [20, 0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [2, 1])[:original]
    assert_equal [30, 0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [3, 0])[:original]
    assert_equal [30, 0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [4, 0])[:original]
    assert_equal [40, 0], Sprockets::SourceMapUtils.bsearch_mappings(mappings, [6, 0])[:original]
  end

  def test_decode_json_source_map
    expected = {
      "version"  => 3,
      "file"     => "hello.js",
      "mappings" => [
        { source: 'b.js', generated: [1, 0], original: [20, 0] },
        { source: 'c.js', generated: [2, 0], original: [30, 0] }
      ],
      "sources" => ["a.js", "b.js", "c.js"],
      "names"   => []
    }
    actual = Sprockets::SourceMapUtils.decode_json_source_map('{"version":3,"file":"hello.js","mappings":"ACmBA;ACUA","sources":["a.js","b.js","c.js"],"names":[]}')
    assert_equal expected, actual
  end

  def test_encode_json_source_map_from_hash
    mappings_hash = [
      { source: 'a.js', generated: [0, 0], original: [0,  0] },
      { source: 'b.js', generated: [1, 0], original: [20, 0] },
      { source: 'c.js', generated: [2, 0], original: [30, 0] }
    ]

    sources  = ["a.js", "b.js", "c.js"]
    names    = []

    assert_equal '{"version":3,"file":"hello.js","mappings":"ACmBA;ACUA","sources":["a.js","b.js","c.js"],"names":[]}',
      Sprockets::SourceMapUtils.encode_json_source_map(mappings_hash, sources: sources, names: names, filename: "hello.js")
  end

  def test_encode_json_source_map_from_string
    mappings_str = "ACmBA;ACUA"
    sources      = ["a.js", "b.js", "c.js"]
    names        = []
    expected     = '{"version":3,"file":"hello.js","mappings":"ACmBA;ACUA","sources":["a.js","b.js","c.js"],"names":[]}'
    actual       = Sprockets::SourceMapUtils.encode_json_source_map(mappings_str, sources: sources, names: names, filename: "hello.js")
    assert_equal expected, actual
  end

  def test_decode_vlq_mappings
    mappings = "AAEAA,QAASA,MAAK,EAAG,CACfC,OAAAC,IAAA,CAAY,eAAZ,CADe"
    sources  = ["script.js"],
    names    = ["hello", "console", "log"]

    assert_equal([
      { source: ["script.js"], generated: [1,  0], original: [3,  0], name: "hello" },
      { source: ["script.js"], generated: [1,  8], original: [3,  9], name: "hello" },
      { source: ["script.js"], generated: [1, 14], original: [3, 14] },
      { source: ["script.js"], generated: [1, 16], original: [3, 17] },
      { source: ["script.js"], generated: [1, 17], original: [4,  2], name: "console" },
      { source: ["script.js"], generated: [1, 24], original: [4,  2], name: "log" },
      { source: ["script.js"], generated: [1, 28], original: [4,  2] },
      { source: ["script.js"], generated: [1, 29], original: [4, 14] },
      { source: ["script.js"], generated: [1, 44], original: [4,  2] },
      { source: ["script.js"], generated: [1, 45], original: [3, 17] }
    ], Sprockets::SourceMapUtils.decode_vlq_mappings(mappings, sources: sources, names: names))
  end

  def test_encode_vlq_mappings
    assert_equal "", Sprockets::SourceMapUtils.encode_vlq_mappings([])

    mappings = [
      { source: 'a.js', generated: [1, 0], original: [1,  0] },
      { source: 'b.js', generated: [2, 0], original: [20, 0] },
      { source: 'c.js', generated: [3, 0], original: [30, 0] }
    ]
    expected = "AAAA;ACmBA;ACUA"
    actual   = Sprockets::SourceMapUtils.encode_vlq_mappings(mappings)
    assert_equal expected, actual
  end

  TESTS = {
    'A'          => [0],
    'C'          => [1],
    'D'          => [-1],
    'E'          => [2],
    'F'          => [-2],
    'K'          => [5],
    'L'          => [-5],
    'w+B'        => [1000],
    'x+B'        => [-1000],
    'gqjG'       => [100000],
    'hqjG'       => [-100000],
    'AAgBC'      => [0, 0, 16, 1],
    'AAgCgBC'    => [0, 0, 32, 16, 1],
    'DFLx+BhqjG' => [-1, -2, -5, -1000, -100000],
    'CEKw+BgqjG' => [1, 2, 5, 1000, 100000]
  }

  MAP_TESTS = {
    'AA,AA;;AACDE' =>
      [[[0, 0], [0, 0]], [], [[0, 0, 1, -1, 2]]],
    ';;;;EAEE,EAAE,EAAC,CAAE;ECQY,UACC' =>
      [[], [], [], [], [[2, 0, 2, 2], [2, 0, 0, 2], [2, 0, 0, 1], [1, 0, 0, 2]], [[2, 1, 8, 12], [10, 0, 1, 1]]],
    'AAEAA,QAASA,MAAK,EAAG,CACfC,OAAAC,IAAA,CAAY,eAAZ,CADe' =>
      [[[0, 0, 2, 0, 0], [8, 0, 0, 9, 0], [6, 0, 0, 5], [2, 0, 0, 3], [1, 0, 1, -15, 1], [7, 0, 0, 0, 1], [4, 0, 0, 0], [1, 0, 0, 12], [15, 0, 0, -12], [1, 0, -1, 15]]],
    ';;;;;EACAA;;EACAC;;EAGA;IAAA;;;EAGAC;IAAS;;;EAGTC;;EAGAC;IACE;IACA;IACA;MAAQ;;;;EAGVC;;;IACE;;;EAGF;IAAA;;;EAGAC;;;IAAQ;;MAAA' =>
      [[], [], [], [], [], [[2, 0, 1, 0, 0]], [], [[2, 0, 1, 0, 1]], [], [[2, 0, 3, 0]], [[4, 0, 0, 0]], [], [], [[2, 0, 3, 0, 1]], [[4, 0, 0, 9]], [], [], [[2, 0, 3, -9, 1]], [], [[2, 0, 3, 0, 1]], [[4, 0, 1, 2]], [[4, 0, 1, 0]], [[4, 0, 1, 0]], [[6, 0, 0, 8]], [], [], [], [[2, 0, 3, -10, 1]], [], [], [[4, 0, 1, 2]], [], [], [[2, 0, 3, -2]], [[4, 0, 0, 0]], [], [], [[2, 0, 3, 0, 1]], [], [], [[4, 0, 0, 8]], [], [[6, 0, 0, 0]]],
    'AACC,SAAQ,EAAG,CAAA,IACCA,CADD,CACOC,CADP,CACaC,CADb,CAC0CC,CAWpDA,EAAA,CAASA,QAAQ,CAACC,CAAD,CAAI,CACnB,MAAOA,EAAP,CAAWA,CADQ,CAIrBJ,EAAA,CAAO,CAAC,CAAD,CAAI,CAAJ,CAAO,CAAP,CAAU,CAAV,CAAa,CAAb,CAEPC,EAAA,CAAO,MACCI,IAAAC,KADD,QAEGH,CAFH,MAGCI,QAAQ,CAACH,CAAD,CAAI,CAChB,MAAOA,EAAP,CAAWD,CAAA,CAAOC,CAAP,CADK,CAHb,CAcc,YAArB,GAAI,MAAOI,MAAX,EAA8C,IAA9C,GAAoCA,KAApC,EACEC,KAAA,CAAM,YAAN,CAGO,UAAQ,EAAG,CAAA,IACdC,CADc,CACVC,CADU,CACJC,CACdA,EAAA,CAAW,EACNF,EAAA,CAAK,CAAV,KAAaC,CAAb,CAAoBX,CAAAa,OAApB,CAAiCH,CAAjC,CAAsCC,CAAtC,CAA4CD,CAAA,EAA5C,CACER,CACA,CADMF,CAAA,CAAKU,CAAL,CACN,CAAAE,CAAAE,KAAA,CAAcb,CAAAM,KAAA,CAAUL,CAAV,CAAd,CAEF,OAAOU,EAPW,CAAX,CAAA,EApCC,CAAX,CAAAG,KAAA,CA8CO,IA9CP' =>
      [[[0, 0, 1, 1], [9, 0, 0, 8], [2, 0, 0, 3], [1, 0, 0, 0], [4, 0, 1, 1, 0], [1, 0, -1, -1], [1, 0, 1, 7, 1], [1, 0, -1, -7], [1, 0, 1, 13, 1], [1, 0, -1, -13], [1, 0, 1, 42, 1], [1, 0, 11, -52, 0], [2, 0, 0, 0], [1, 0, 0, 9, 0], [8, 0, 0, 8], [1, 0, 0, 1, 1], [1, 0, 0, -1], [1, 0, 0, 4], [1, 0, 1, -19], [6, 0, 0, 7, 0], [2, 0, 0, -7], [1, 0, 0, 11, 0], [1, 0, -1, 8], [1, 0, 4, -21, -4], [2, 0, 0, 0], [1, 0, 0, 7], [1, 0, 0, 1], [1, 0, 0, -1], [1, 0, 0, 4], [1, 0, 0, -4], [1, 0, 0, 7], [1, 0, 0, -7], [1, 0, 0, 10], [1, 0, 0, -10], [1, 0, 0, 13], [1, 0, 0, -13], [1, 0, 2, -7, 1], [2, 0, 0, 0], [1, 0, 0, 7], [6, 0, 1, 1, 4], [4, 0, 0, 0, 1], [5, 0, -1, -1], [8, 0, 2, 3, -3], [1, 0, -2, -3], [6, 0, 3, 1, 4], [8, 0, 0, 8], [1, 0, 0, 1, -3], [1, 0, 0, -1], [1, 0, 0, 4], [1, 0, 1, -16], [6, 0, 0, 7, 0], [2, 0, 0, -7], [1, 0, 0, 11, -1], [1, 0, 0, 0], [1, 0, 0, 7, 1], [1, 0, 0, -7], [1, 0, -1, 5], [1, 0, -3, -13], [1, 0, 14, 14], [12, 0, 0, -21], [3, 0, 0, 4], [6, 0, 0, 7, 4], [6, 0, 0, -11], [2, 0, 0, 46], [4, 0, 0, -46], [3, 0, 0, 36, 0], [5, 0, 0, -36], [2, 0, 1, 2, 1], [5, 0, 0, 0], [1, 0, 0, 6], [12, 0, 0, -6], [1, 0, 3, 7], [10, 0, 0, 8], [2, 0, 0, 3], [1, 0, 0, 0], [4, 0, 1, -14, 1], [1, 0, -1, 14], [1, 0, 1, -10, 1], [1, 0, -1, 10], [1, 0, 1, -4, 1], [1, 0, 1, -14, 0], [2, 0, 0, 0], [1, 0, 0, 11], [2, 0, 1, -6, -2], [2, 0, 0, 0], [1, 0, 0, 5], [1, 0, 0, -10], [5, 0, 0, 13, 1], [1, 0, 0, -13], [1, 0, 0, 20, -11], [1, 0, 0, 0, 13], [7, 0, 0, -20], [1, 0, 0, 33, -3], [1, 0, 0, -33], [1, 0, 0, 38, 1], [1, 0, 0, -38], [1, 0, 0, 44, -1], [1, 0, 0, 0], [2, 0, 0, -44], [1, 0, 1, 2, -8], [1, 0, 1, 0], [1, 0, -1, 6, -2], [1, 0, 0, 0], [1, 0, 0, 5, 10], [1, 0, 0, -5], [1, 0, 1, -6], [1, 0, 0, 0, 2], [1, 0, 0, 0, 2], [5, 0, 0, 0], [1, 0, 0, 14, -13], [1, 0, 0, 0, 6], [5, 0, 0, 0], [1, 0, 0, 10, -5], [1, 0, 0, -10], [1, 0, 0, -14], [1, 0, 2, -2], [7, 0, 0, 7, 10], [2, 0, -7, 11], [1, 0, 0, -11], [1, 0, 0, 0], [2, 0, -36, 1], [1, 0, 0, -11], [1, 0, 0, 0, 3], [5, 0, 0, 0], [1, 0, 46, 7], [4, 0, -46, -7]]]
  }

  def test_vlq_encode
    TESTS.each do |str, int|
      assert_equal str, Sprockets::SourceMapUtils.vlq_encode(int)
    end
  end

  def test_vlq_decode
    TESTS.each do |str, int|
      assert_equal int, Sprockets::SourceMapUtils.vlq_decode(str)
    end
  end

  def test_vlq_encode_decode
    (-255..255).each do |int|
      encode = Sprockets::SourceMapUtils.vlq_encode([int])
      assert_equal [int], Sprockets::SourceMapUtils.vlq_decode(encode)
    end
  end

  def test_vlq_encode_mappings
    MAP_TESTS.each do |str, ary|
      assert_equal str, Sprockets::SourceMapUtils.vlq_encode_mappings(ary)
    end
  end

  def test_vlq_decode_mappings
    MAP_TESTS.each do |str, ary|
      assert_equal ary, Sprockets::SourceMapUtils.vlq_decode_mappings(str)
    end
  end
end
