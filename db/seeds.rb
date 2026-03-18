dict_path = Rails.root.join("db", "cmu_dict", "cmudict-0.7b.txt")

unless File.exist?(dict_path)
  puts "CMU dictionary not found at #{dict_path}"
  puts "Download it: curl -L -o db/cmu_dict/cmudict-0.7b.txt https://raw.githubusercontent.com/cmusphinx/cmudict/master/cmudict.dict"
  exit 1
end

puts "Parsing CMU dictionary..."
count = 0
batch = []

CmuDictParser.parse_file(dict_path) do |attrs|
  batch << attrs
  if batch.size >= 1000
    Word.insert_all(batch, unique_by: :text)
    count += batch.size
    batch.clear
    print "."
  end
end

if batch.any?
  Word.insert_all(batch, unique_by: :text)
  count += batch.size
end

puts "\nSeeded #{count} words (#{Word.count} in database)"
(2..8).each do |n|
  puts "  #{n} phonemes: #{Word.where(phoneme_count: n).count} words"
end
