rmc <- subset(gpsmorn, V1 == "$GPRMC")[, -c(11:12, 14:15)]
colnames(rmc) <- c('sentence', 'time', 'status', 'lat', 'NS', 'lon', 'EW', 'speed', 'angle', 'date', 'checksum')
rmc$time <- round(rmc$time)
rmc$date  <- round(rmc$date)
rmc$time <- format(as.POSIXct(paste(rmc$time, ' 0', rmc$date, sep = ''), format = '%H%M%S %d%m%y', tz = 'UTC'), tz = Sys.timezone())
rmc <- rmc[, -10]
rmc$lat <- as.numeric(rmc$lat)/6000 + round(as.numeric(rmc$lat)/100)
rmc$lon <- -as.numeric(rmc$lon)/6000 + round(-as.numeric(rmc$lon)/100)
rmc$speed <- rmc$speed * 1.852 # knots to km/h

