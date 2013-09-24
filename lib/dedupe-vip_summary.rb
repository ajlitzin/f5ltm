#de-dupe my simple lon3 vip fqdn host file for devops

f = File.open("../private-fixtures/lon3/vip_summary.txt", 'r')
dupes_array=[]
f.each_line { |line| dupes_array.push(line)}
f.close
dupes_array.uniq!

File.open("../private-fixtures/lon3/vip_summary-nodupes.txt", 'w') do |no_dupes_file|
  dupes_array.each do |line|
    no_dupes_file.write(line.sub(/lon3\./,''))
  end
end
