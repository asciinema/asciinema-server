class JsonFileWriter

  def write_enumerable(file, array)
    first = true
    file << '['

    array.each do |item|
      if first
        first = false
      else
        file << ','
      end

      file << item.to_json
    end

    file << ']'
    file.close
  end

end
