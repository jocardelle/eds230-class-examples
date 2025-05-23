#' Solar PV Output
#'
#' Computes electricity from a photovoltaic system given incoming solar radiation
#' @param area area of panel (m2)
#' @param eff solar panel efficiency (0-1) default 0.8
#' @param PR performance ratio (system related) (0-1) default is 0.75
#' @param solar  array with the following columns day month year Kdown_direct Kdown_diffuse (kJ/m2/day)
#' @param eunits energy output: J results in kJ/m2/year or W then assume KWh, default = J
#' @param ethresh threshold radiation (kJ/m2) below which efficiency fall to 0
#' @param g TRUE/FALSE  graph results default=TRUE
#' @param clr colour of grph default "blue"
#' @param etype "both" uses both direct and diffuse, "direct' direct only, "diffuse" diffuse only default="both"
#' @author Naomi
#' @return annual (power for each year), avg (average power) (see eunits for units)


library(tidyverse)
library(here)
library(dplyr)
load(here("data/sierraczosolar.rda"))


solarpv <- function(area, eff = 0.8, PR = 0.75, solar = sierraczosolar, clr = "blue", eunits = "J", etype = "both", g = TRUE, ethresh = 10000) {
  # calculate total daily energy - depending on whether array can use diffuse
  if (etype == "diffuse") {
    solar$total <- solar$Kdown_diffuse
  } else {
    if (etype == "direct") {
      solar$total <- solar$Kdown_direct
    } else {
      solar$total <- solar$Kdown_direct + solar$Kdown_diffuse
    }
  }

  # array efficiency declines linearly when solar is below a threshold
  # make an internal function to adjust efficiency based on this

  adjusteff <- function(x, ethresh, eff) {
    result <- ifelse((x > ethresh), eff * x, x * eff * (max(0, x / ethresh)))
    return(result)
  }

  # apply the efficiency function to the solar radiation data
  solar <- solar %>% mutate(Kadj = adjusteff(total, ethresh = ethresh, eff = eff))


  # aggregate by year to get annual radiation totals
  annualsolar <- solar %>%
    group_by(year) %>%
    dplyr::summarize(Kadj = sum(Kadj))


  # compute electricity based on annual radiation
  annualsolar$elect <- area * PR * annualsolar$Kadj

  ylbs <- "kJ/yr"
  # unit conversion if needed
  if (eunits == "W") {
    annualsolar$elect <- annualsolar$elect * 0.278
    ylbs <- "Wh/yr"
  }

  # plot if users requested
  if (g) {
    barplot(annualsolar$elect, names = annualsolar$year, col = clr, ylab = ylbs, xlab = "Year")
  }

  return(list(annual = annualsolar[, c("year", "elect")], mean = mean(annualsolar$elect)))
}


solarpv(area = 12)
