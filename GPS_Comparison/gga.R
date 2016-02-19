gga <- subset(gpsmorn, V1 == "$GPGGA")[, -c(11, 13, 14:15)]
colnames(gga) <- c('sentence', 'time', 'lat', 'NS', 'lon', 'EW', 'quality', 'satellites', 'dilution',  'altitude', 'height')
gga$time <- round(gga$time)
date <- unique(round(subset(gpsmorn, V10 > 10000)$V10))
gga$time <- format(as.POSIXct(paste(gga$time, ' 0', date, sep = ''), format = '%H%M%S %d%m%y', tz = 'UTC'), tz = Sys.timezone())
gga$lat <- (as.numeric(gga$lat)/100 - floor(as.numeric(gga$lat)/100))*100/60 + floor(as.numeric(gga$lat)/100)
gga$lon <- (as.numeric(gga$lon)/100 - round(as.numeric(gga$lon)/100))*100/60 + round(as.numeric(gga$lon)/100)
gga$lon <- -gga$lon
gga$speed <- rmc$speed


