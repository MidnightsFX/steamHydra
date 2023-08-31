
module SteamHydra
    
  # Bepinex's default log can grow infinitely in size, this function will truncate the file to zero if it is over a certain size.
  # default size max of 2G
  def self.truncate_log(location, bytesize: 2_000_000_000, rotated_size: 2_000_000)
    begin
    filesize = File.size(location)
    if filesize > bytesize
      LOG.debug("Log file #{location} size: #{filesize} larger than allocated, performing truncation.")
      File.truncate(location, rotated_size)
    else
      LOG.debug("No log rotation needed for file #{location} size: #{filesize}")
    end
    rescue => e
      LOG.warn("Recieved error when trying to truncate log: #{e}")
    end
  end
end