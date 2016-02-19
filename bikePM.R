dat <- read.csv("C:/Users/al/Dropbox/bikePM/GPSLOG_20150806.TXT")
# dat <- data.frame(time = paste(dat$time, dat$X), dat[, -(1:2)])
dat$time <- as.POSIXct(format(as.POSIXct(dat$time, tz = 'UTC'), tz = Sys.timezone()))
dat <- subset(dat, time > as.POSIXct('2015-08-06 09:05:00'))
dat <- subset(dat, time < as.POSIXct('2015-08-06 09:28:00'))

require(ggmap)
library(gridExtra)
base <- get_map('Milledge at Prince Avenue, Athens, GA', zoom = 14)
base <- ggmap(base, extent = 'panel')
pmMap <- base + 
  geom_path(aes(dat$lon, dat$lat, color = pm_filt), data = dat, lwd = 2) + 
  scale_color_continuous(low = "forestgreen", high = "red")
pm <- ggplot() + geom_line(aes(time, pm_filt, color = pm_filt), data = dat) + 
  theme_classic() + ylab('PM Response (% Full Scale)') +
  scale_color_continuous(low = "forestgreen", high = "red")

vocMap <- base + geom_path(aes(dat$lon, dat$lat, color = voc), data = dat, lwd = 2) + 
  scale_color_continuous(low = "forestgreen", high = "red")
voc <- ggplot() + geom_line(aes(time, voc, color = voc), data = dat) + 
  theme_classic() + ylab('VOC Response (mV)') + 
  scale_color_continuous(low = "forestgreen", high = "red")

alt <- ggplot() + geom_line(aes(time, alt, color = pm_filt), data = dat) + 
  theme_classic()  + ylab('Altitude (m)') +
  scale_color_continuous(low = "forestgreen", high = "red")
speed <- ggplot() + geom_line(aes(time, speed*1.15, color = pm_filt), data = dat) + 
  theme_classic() + ylab('Speed (mph)') +
  scale_color_continuous(low = "forestgreen", high = "red")

grid.arrange(pmMap, vocMap, pm, voc, alt, speed, ncol = 2)
