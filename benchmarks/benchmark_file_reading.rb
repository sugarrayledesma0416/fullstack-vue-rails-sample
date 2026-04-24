require 'benchmark'

def read_bytes(offset, bytes, filepath)
  file = File.open(filepath, 'r')
  file.pos = offset
  xml = file.read(bytes)
  xml.force_encoding('utf-8')
  file.close()
  xml
end

def read_char(offset, bytes, filepath)
  xml = ''
  file = File.open(filepath, 'r')
  file.pos = offset
  file.each_char do |char|
    if xml.bytesize >= bytes
      break
    else
      xml << char
    end
  end
  file.close()
  xml
end

n = 50000

filepath = File.join('spec', 'fixtures', 'xml', 'ruby187_responses_with_accents.xml')

Benchmark.bmbm do |bench|


  bench.report "char by char" do
    n.times{ read_char(1506, 696, filepath) }
  end

  bench.report "read bytes" do
    n.times{ read_bytes(1506, 696, filepath) }
  end

end
