
module SteamHydra
    
  # Bepinex's default log can grow infinitely in size, this function will truncate the file to zero if it is over a certain size.
  # default size max of 2G
  def self.rotate_bepinex_log(location, bytesize: 2_000_000_000, rotated_size: 2_000_000)
    filesize = File.size(location)
    if filesize > bytesize
      LOG.debug("Log file #{location} size: #{filesize} larger than allocated, performing truncation.")
      File.truncate(location, rotated_size)
    else
      LOG.debug("No log rotation needed for file #{location} size: #{filesize}")
    end
  end
end