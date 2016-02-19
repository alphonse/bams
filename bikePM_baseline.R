# dat <- read.csv("C:/Users/al/Documents/GitHub/bikePM/data/log/GPSLOG_20150812.TXT")
dat <- read.csv("~/Documents/Electronics_Programming/bams/data/log/GPSLOG_20150813P.TXT", stringsAsFactors=FALSE)
dat$time <- as.POSIXct(format(as.POSIXct(dat$time, tz = 'UTC'), tz = Sys.timezone()))
# dat <- subset(dat, time > as.POSIXct('2015-08-12 17:30:00'))
# dat <- subset(dat, time < as.POSIXct('2015-08-06 09:28:00'))
dat <- subset(dat, pm_raw != 'Inf')
dat <- subset(dat, class(dat$time) != "POSIXct")

require(baseline)
# dat$voc <- t(baseline.lowpass(matrix(dat$voc, nrow = 1))$corrected)
# dat$voc <- dat$voc + abs(min(dat$voc))
# dat$pm_filt <- t(baseline.lowpass(matrix(dat$pm_filt, nrow = 1))$corrected)
# for (i in 1:nrow(dat)) {
#   if (i == 1) dat$pm_filt[i] <- dat$pm_raw[i]
#   else {
#     dat$pm_filt[i] <- 0.9 * dat$pm_filt[1:(i-1)] + 0.1 * dat$pm_raw[i]
#   }
# }

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
  theme_classic() + ylab('VOC Response (a.u.)') + 
  scale_color_continuous(low = "forestgreen", high = "red")

alt <- ggplot() + geom_line(aes(time, alt, color = pm_filt), data = dat) + 
  theme_classic()  + ylab('Altitude (m)') +
  scale_color_continuous(low = "forestgreen", high = "red")
speed <- ggplot() + geom_line(aes(time, speed*1.15, color = pm_filt), data = dat) + 
  theme_classic() + ylab('Speed (mph)') +
  scale_color_continuous(low = "forestgreen", high = "red")

grid.arrange(pmMap, vocMap, pm, voc, alt, speed, ncol = 2)

