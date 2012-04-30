require 'test/unit'
require 'sprockets/source_map'

class TestSourceMap < Test::Unit::TestCase
  def test_mappings
    hash = {
      'version' => 3,
      'file' => "script.min.js",
      'lineCount' => 1,
      'mappings' => "AAEAA,QAASA,MAAK,EAAG,CACfC,OAAAC,IAAA,CAAY,eAAZ,CADe;",
      'sources' => ["script.js"],
      'names' => ["hello", "console", "log"]
    }
    map = Sprockets::SourceMap.from_hash(hash)

    assert mapping = map.mappings[0]
    assert_equal 1, mapping.generated.line
    assert_equal 0, mapping.generated.column
    assert_equal 2, mapping.original.line
    assert_equal 0, mapping.original.column
    assert_equal 'script.js', mapping.source
    assert_equal 'hello', mapping.name

    assert mapping = map.mappings[-1]
    assert_equal 1, mapping.generated.line
    assert_equal 45, mapping.generated.column
    assert_equal 2, mapping.original.line
    assert_equal 17, mapping.original.column
    assert_equal 'script.js', mapping.source
    assert_equal nil, mapping.name

    assert_equal hash['version'],   map.version
    assert_equal hash['lineCount'], map.line_count
    assert_equal hash['sources'],   map.sources
    assert_equal hash['names'],     map.names
    assert_equal hash['mappings'],  map.mappings.to_s

    assert_equal hash, map.as_json
  end

  def test_mappings2
    hash = {
      'version' => 3,
      'file' => "example.js",
      'lineCount' => 43,
      'mappings' => ";;;;;EACAA;;EACAC;;EAGA;IAAA;;;EAGAC;IAAS;;;EAGTC;;EAGAC;IACE;IACA;IACA;MAAQ;;;;EAGVC;;;IACE;;;EAGF;IAAA;;;EAGAC;;;IAAQ;;MAAA;",
      'sources' => ["example.coffee"],
      'names' => ["number", "opposite", "square", "list", "math", "race", "cubes"]
    }
    map = Sprockets::SourceMap.from_hash(hash)

    assert mapping = map.mappings[0]
    assert_equal 6, mapping.generated.line
    assert_equal 2, mapping.generated.column
    assert_equal 1, mapping.original.line
    assert_equal 0, mapping.original.column
    assert_equal 'example.coffee', mapping.source
    assert_equal 'number', mapping.name

    assert mapping = map.mappings[-1]
    assert_equal 43, mapping.generated.line
    assert_equal 6, mapping.generated.column
    assert_equal 27, mapping.original.line
    assert_equal 8, mapping.original.column
    assert_equal 'example.coffee', mapping.source
    assert_equal nil, mapping.name

    assert_equal hash['version'],   map.version
    assert_equal hash['lineCount'], map.line_count
    assert_equal hash['sources'],   map.sources
    assert_equal hash['names'],     map.names
    assert_equal hash['mappings'],  map.mappings.to_s
  end

  def test_mappings3
    hash = {
      'version' => 3,
      'file' => "example.min.js",
      'lineCount' => 1,
      'mappings' => "AACC,SAAQ,EAAG,CAAA,IACCA,CADD,CACOC,CADP,CACaC,CADb,CAC0CC,CAWpDA,EAAA,CAASA,QAAQ,CAACC,CAAD,CAAI,CACnB,MAAOA,EAAP,CAAWA,CADQ,CAIrBJ,EAAA,CAAO,CAAC,CAAD,CAAI,CAAJ,CAAO,CAAP,CAAU,CAAV,CAAa,CAAb,CAEPC,EAAA,CAAO,MACCI,IAAAC,KADD,QAEGH,CAFH,MAGCI,QAAQ,CAACH,CAAD,CAAI,CAChB,MAAOA,EAAP,CAAWD,CAAA,CAAOC,CAAP,CADK,CAHb,CAcc,YAArB,GAAI,MAAOI,MAAX,EAA8C,IAA9C,GAAoCA,KAApC,EACEC,KAAA,CAAM,YAAN,CAGO,UAAQ,EAAG,CAAA,IACdC,CADc,CACVC,CADU,CACJC,CACdA,EAAA,CAAW,EACNF,EAAA,CAAK,CAAV,KAAaC,CAAb,CAAoBX,CAAAa,OAApB,CAAiCH,CAAjC,CAAsCC,CAAtC,CAA4CD,CAAA,EAA5C,CACER,CACA,CADMF,CAAA,CAAKU,CAAL,CACN,CAAAE,CAAAE,KAAA,CAAcb,CAAAM,KAAA,CAAUL,CAAV,CAAd,CAEF,OAAOU,EAPW,CAAX,CAAA,EApCC,CAAX,CAAAG,KAAA,CA8CO,IA9CP;",
      'sources' => ["example.js"],
      'names' => ["list","math","num","square","x","Math","sqrt","cube","elvis","alert","_i","_len","_results","length","push","call"]
    }
    map = Sprockets::SourceMap.from_hash(hash)

    assert mapping = map.mappings[0]
    assert_equal 1, mapping.generated.line
    assert_equal 0, mapping.generated.column
    assert_equal 1, mapping.original.line
    assert_equal 1, mapping.original.column
    assert_equal 'example.js', mapping.source
    assert_equal nil, mapping.name

    assert mapping = map.mappings[-1]
    assert_equal 1, mapping.generated.line
    assert_equal 289, mapping.generated.column
    assert_equal 1, mapping.original.line
    assert_equal 1, mapping.original.column
    assert_equal 'example.js', mapping.source
    assert_equal nil, mapping.name

    assert_equal hash['version'],   map.version
    assert_equal hash['lineCount'], map.line_count
    assert_equal hash['sources'],   map.sources
    assert_equal hash['names'],     map.names
    assert_equal hash['mappings'],  map.mappings.to_s
  end
end


class TestMappings < Test::Unit::TestCase
  Offset   = Sprockets::SourceMap::Offset
  Mapping  = Sprockets::SourceMap::Mapping
  Mappings = Sprockets::SourceMap::Mappings

  def setup
    @mappings = Mappings.new([
      Mapping.new('a.js', Offset.new(0, 0), Offset.new(0, 0)),
      Mapping.new('b.js', Offset.new(1, 0), Offset.new(0, 0)),
      Mapping.new('c.js', Offset.new(2, 0), Offset.new(0, 0))
    ])
  end

  def test_line_count
    # assert_equal 3, @mappings.line_count
  end

  def test_to_s
    assert_equal "ACAA;ACAA;", @mappings.to_s
  end

  def test_sources
    assert_equal ["a.js", "b.js", "c.js"], @mappings.sources
  end

  def test_names
    assert_equal [], @mappings.names
  end

  def test_add
    mappings2 = Mappings.new([
      Mapping.new('d.js', Offset.new(0, 0), Offset.new(0, 0))
    ])
    mappings3 = @mappings + mappings2
    assert_equal 0, mappings3[0].generated.line
    assert_equal 1, mappings3[1].generated.line
    assert_equal 2, mappings3[2].generated.line
    assert_equal 3, mappings3[3].generated.line
  end
end

class TestMapping < Test::Unit::TestCase
  Offset  = Sprockets::SourceMap::Offset
  Mapping = Sprockets::SourceMap::Mapping

  def setup
    @mapping = Mapping.new('script.js', Offset.new(1, 8), Offset.new(2, 9), 'hello')
  end

  def test_generated
    assert_equal 1, @mapping.generated.line
    assert_equal 8, @mapping.generated.column
  end

  def test_original
    assert_equal 2, @mapping.original.line
    assert_equal 9, @mapping.original.column
  end

  def test_source
    assert_equal 'script.js', @mapping.source
  end

  def test_name
    assert_equal 'hello', @mapping.name
  end

  def test_inspect
    assert_equal "#<Sprockets::SourceMap::Mapping generated=1:8, original=2:9, source=script.js, name=hello>", @mapping.inspect
  end
end

class TestOffset < Test::Unit::TestCase
  Offset = Sprockets::SourceMap::Offset

  def setup
    @offset = Offset.new(1, 5)
  end

  def test_line
    assert_equal 1, @offset.line
  end

  def test_column
    assert_equal 5, @offset.column
  end

  def test_to_s
    assert_equal "1:5", @offset.to_s
  end

  def test_inspect
    assert_equal "#<Sprockets::SourceMap::Offset line=1, column=5>", @offset.inspect
  end

  def test_add_offset
    offset = @offset + Offset.new(2, 1)
    assert_equal 3, offset.line
    assert_equal 6, offset.column
  end

  def test_add_line
    offset = @offset + 5
    assert_equal 6, offset.line
    assert_equal 5, offset.column
  end
end
