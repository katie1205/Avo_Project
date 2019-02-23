---
title: "Time Series Analysis of Avocado Sales in Houston, Texas"
author: 'Team9: Rebecca Crawford, Elisabeth McGowen, and Kathryn Sinders'
date: "December 1, 2018"
output: rmarkdown::github_document
---


##Introduction

Recently deemed a highly nutritious superfood, the avocado is a savory green fruit coveted by many Americans. The avocado fares well in warm climates, a seasonal constraint that historically explained avocad
o scarcity in US winters. Mexico has evaded this constraint, as its warm climate is conducive to growing and harvesting the fruit year round. In 1914, Mexican avocado imports to the United States were banned due to phytosanitary issues and competing growers in California. The ban was eventually lifted in 1994, following the enaction of the North American Free Trade Agreement (NAFTA). Shortly thereafter, the fruit became available in US supermarkets year round.

Following the emergence of the American superfood trend, this annually accesssible fruit has recently skyrocketed in popularity, with 9 million instances of #avocado trending on Instagram at any given time (*#Avocado*). According to Mike Knowles of *Fruit Logistica*, crafty marketing is also responsible for the fruit's upsurge. In fact, the avocado is the only type of produce that has ever been advertised during the superbowl (Ferdmen).  The *Latest Fruit Market Trending Data* from the Hass Avocado Board reports that avocado sales volume reached a national 35.5% growth in the quarter ending July 1, 2018.  Americans currently consume 7 pounds of avocados per person each year as compared to about one pound each in 1989 (Handwerk). 

**_Problem_**  

Avocado sales data were obtained from kaggle.com (Kiggins). The file contained the weekly average volumes of conventional avocados in cities across the United States. Based on our research, we hypothesized that avocado sales volume would continue to rise in Houston.

**_Purpose_**  

To guide retailers, investors, and consumers toward profitable and affordable solutions, it would be to useful to forecast future values of avocado volumes. Controlling volume, and consequently price, is especially crucial in Mexico's neighboring regions, particularly in Houston, TX where obesity and cardiovascular diseases are prevalent among the poor. Thus, the ultimate goal of this analysis was to forecast future values of avocado volume. Using the Box-Jenkins method, this process would entail stationarizing, proposing ARIMA(p,d,q) candidates based on autocorrelations, estimating parameters, evaluating subsequent models, and forecasting future values for the series.

##Results and Discussion
```{r, include=FALSE}
#This chunk shows the data cleaning we completed to get to the cleaned dataset
#Filter for Houston, filter for conventional avocados only, only keep the date and volume columns, order by date descending
library(dplyr)
library(readxl)
avocado <- read_excel("C:/Users/sooch/Desktop/avocado.xlsx")
avocado<-as.data.frame(avocado)
str(avocado)
colnames(avocado)[4]<-"Total_Volume"
str(avocado)
avo_clean <- avocado %>% filter(region == 'Houston') %>% filter(type=="conventional") %>% select(Date,Total_Volume) %>% mutate(Date = as.Date(Date, "%Y-%m-%d")) %>% arrange(Date)
```

```{r, include = FALSE}

#Select desired response variable
avo_dat_vol <- avo_clean %>% select(Date, Total_Volume)

#Create time series object
vol_reg_ts <- ts(avo_dat_vol$Total_Volume, frequency = 52, start = c(2015, 1), end = c(2018, 13))
head(vol_reg_ts)
```

The timeframe for the 169 weekly observations for average Avocado volume ranged from January 4, 2015 to March 25, 2018. To create a time series object from the file, we selected only our desired sales volume variable and date, and utilized the ts( ) function with a frequency of 52. 

**_Data Exploration_**  

The original time series is plotted below:

```{r echo = FALSE, message = FALSE, warning = FALSE}

#Plot original time series
ts.plot(vol_reg_ts, main = "Weekly Avocado Sales Vol (Houston, 2015-2018)", ylab = "Sales Volume")
```

As illustrated in the above plot, avocado sales volume appeared non-stationary. Avocado volume remained moderately constant from 2015 until late 2016/early 2017. From then onward, the series fluctuated, exhibiting slightly more variability. A steep, upward trend emerged just before 2018, followed by a sharp decline immediately thereafter. We surmised that a stationary series could be attained through the following two transformations. The trends could be eliminated through differencing while a natural logarithm transformation might stabilize the non-constant variance. Before manipulating the data, however, the ACF and PACF were plotted and examined.

```{r echo = FALSE, message = FALSE, warning = FALSE}
#Load necessary library
library(astsa)

#Plot ACF and PACF
acf2(vol_reg_ts, max.lag = 100, main = "Avocado Volume Correlograms")[0] 
```

As anticipated, the ACF decayed gradually, thus confirming non-stationarity. The ACF also appeared to exhibit slightly cyclical behavior, oscillating between marginally significant negative and positive values roughly every 0.5 increments (half a year) as it gradually tailed off. Before addressing potential seasonality, however, the data still needed to be stationarized. 

**_Stationarizing_**  

As previously stated, the two violations of stationarity conditions called for both types of transformations: the logarithm transformation and the first difference. Both transformations were applied, and the plots of the resulting time series are shown below:

```{r include = FALSE}

#Try different ransformations
vol_reg_ts_diff <- diff(vol_reg_ts)  #First Difference
vol_reg_ts_log <- log(vol_reg_ts)  #Log Transformation
vol_reg_ts_diff_log <- diff(log(vol_reg_ts)) #Difference-of-Log transformation

#EDA to determine if seasonality is present

library(forecast)

ggseasonplot(vol_reg_ts, main = "Original Series Seasonplot")
ggmonthplot(vol_reg_ts)

ggseasonplot(vol_reg_ts_diff, main = "Differenced Series Seasonplot")
ggmonthplot(vol_reg_ts_diff)

ggseasonplot(vol_reg_ts_diff_log, main = "Difference-of-Log Series Seasonplot")
ggmonthplot(vol_reg_ts_diff_log)

#While the series fluctuates a lot, distinct, consistent seasonal pattern was not observed in the above season plot. 
```
```{r echo = FALSE, fig.height = 3, fig.width = 3.2}

#Plot first and second differences together to compare

ts.plot(vol_reg_ts_diff, main = "First Difference")
ts.plot(vol_reg_ts_diff_log, main = "Difference-of-Log")
```

While the plots for both series were fairly similar, the difference-of-log series appeared to have a more constant variance as evidenced by the following observation: the range of values in the first half more closely resembled that of the second half. Based on its apparent improved stationarity, the difference-of-log transformed series was used in our proceeding analysis. Analysis of PACF and ACF plots for each transformation further reaffirmed this decision (as shown below in the .Rmd file). 

```{r include = FALSE}

acf2(vol_reg_ts_diff, max.lag = 100, main = "Differenced Series Correlograms")[0]  #First Difference---> somewhat stationary
acf2(vol_reg_ts_log, max.lag = 150, main = "Log-Transformed Correlograms")[0] #Gradual decay -----> Non-stationary
```
```{r echo = FALSE}

acf2(vol_reg_ts_diff_log, max.lag = 100, main = "Difference-of-Log Transformed Correlograms")[0]
```

The ACF above confirms that the series has been stationarized. There does not seem to be any evidence of seasonality since nearly every ACF and PACF value after lag = 2 is statistically insignificant. There are a few values that extend past the confidence bounds, but we would argue that this is most likely due to noise in the data since there is no distinguishable pattern. We also assessed seasonality of the data using ggseasonplot( ) and ggmonthplot( ), but found no evidence of seasonality (in .Rmd file).

In accordance with the Box-Jenkins method, we examined the behavior of the ACF and PACF of the series and compared it to the general expectations for known ARMA(p,q) classes. The ACF and the PACF plots resembled one another, and both could arguably have been exhibiting either one of the following two behaviors: a cut-off after the second lag or a tail-off. It was difficult to assess the signficance of lags that extended only slightly beyond the confidence bounds in each plot. If we had interpreted both as cutting off after lag = 2, then an MA(2) model (or equivalently, an ARIMA(0,1,2) for the *un*differenced, log-transformed data) would be optimal. If we had instead interpreted the ACF as tailing off and the PACF as cutting off, then an AR(2) model (or an ARIMA(2,1,0) for the *un*differenced, log-transformed data) would be a reasonable proposition. Finally, if we had interpreted *both* ACF and PACF as tailing off, then an ARIMA(p,d,q) model would be the prime candidate. We examined the EACF for this third model and found that the order should be ARIMA(1,1,2). Consequently, three potential candidates emerged:

```{r include = FALSE}

#Let's look at the EACF for possible orders of an ARIMA(p,d,q).

#Load necessary library

library(TSA)

#Run eacf function

eacf(vol_reg_ts_log) #here we are only applying eacf to the undifferenced data for accurate results

#The EACF seems to show a vertex at 1,2 which would suggest an ARIMA(1,1,2) for the undifferenced (but log transformed) data.
```

**_Model Fitting_**  

As mentioned previously, our three candidates were:

-Candidate #1: ARIMA(0,1,2) 

-Candidate #2: ARIMA(2,1,0)

-Candidate #3: ARIMA(1,1,2)

```{r, include=FALSE}

(m1 <- sarima(vol_reg_ts_log, 0, 1, 2)) #ARIMA(0,1,2)   theta=c(-0.3434,-0.2409)  constant=0.0028
#Both coefficients are significant, but the constant is not. Run again with no.constant = TRUE.
(m1_nc <- sarima(vol_reg_ts_log, 0, 1, 2, no.constant = TRUE))   #theta=c(-0.3416, -0.2375)
#This model appears sufficient even though the Q-Q plot points somewhat stray from normality

(m2 <- sarima(vol_reg_ts_log, 2, 1, 0)) #ARIMA(2,1,0)  phi=c(-0.312, -0.3163)  constant=0.0030
#Both coefficients are significant, but the constant is not. This model appears to be sufficient, but the Q-Q plot points stray further from normality than the previous option.
(m2_nc <- sarima(vol_reg_ts_log, 2, 1, 0, no.constant = TRUE)) #phi=c(-0.3117, -0.3158)
#coefficient estimates were both significant; no noticeable difference for outputted plots compared to m2

(m3 <- sarima(vol_reg_ts_log, 1, 1, 2)) #ARIMA(1,1,2)
#Only the MA(2) coefficient is significant to this model, and similar to m2, the Q-Q plot points stray quite a bit from the normal line. Also, some of the p-values for the Ljung-Box statistic fall at least halfway below the confidence line.
(m3_nc <- sarima(vol_reg_ts_log, 1, 1, 2, no.constant = TRUE))
```

In accordance with Box-Jenkins, parameters were estimated for the candidate classes proposed and the resulting models' standardized residuals were analyzed to evaluate goodness-of-fit. We utilized the sarima( ) function to assess diagnostics for all three candidates (all outputs and their interpretations can be viewed in .Rmd file) and ultimately selected the non-constant model esimated for Candidate #1 as our final model. The Ljung-Box statistics plot, QQ-plots, and residual correlograms supplied by sarima( ) were examined to determine whether assumptions had been violated for this model or if any of the model's residuals were autocorrelated. The outputted plots are displayed below:

```{r fig.height = 5}

#Constant was revealed to be insignificant, so here we are applying no.constant = TRUE.

#We are also applying this differencing model to the log-transformed data.

sarima(vol_reg_ts_log, 0, 1, 2, no.constant = TRUE)
```

The time plot of the residuals did not indicate any obvious pattern, and most autocorrelations remained within the confidence bounds for all lags. Although some of the Q-Q plot points *were* outside of the confidence bounds, this plot displayed the closest distribution to normal of the three by far. Finally, the p-values for all Ljung-Box statistics exceeded ${\alpha}=0.05$. Thus we felt strongly that this was a good candidate. Next, we compared the AIC, AICc, and BIC of all three models for additional confirmation.

```{r include = FALSE}

compare <- matrix(c(m1_nc$AIC, m1_nc$AICc, m1_nc$BIC, m2_nc$AIC, m2_nc$AICc, m2_nc$BIC, m3_nc$AIC, m3_nc$AICc, m3_nc$BIC), 3, 3)
colnames(compare) <- c("ARIMA(0,1,2)", "ARIMA(2,1,0)","ARIMA(1,1,2)")
```
```{r echo = FALSE}
compare
```

As shown in the above matrix, all information criterias preferred the ARIMA(0,1,2) model, and we agreed. In terms of the volume series, $x_t$, this model can be expressed algebraically as:

$ln({x_t}) - ln({x_{t-1}})= {w_t} - 0.3416{w_{t-1}} - 0.2375{w_{t-2}}$

*where $w_t$ is uncorrelated, white noise and ln denotes the natural logarithm, or logarithm with base e. *

**_Forecasting_**  

To ensure our model was sufficient, we analyzed the forecasted values for the next quarter (13 weeks). 

```{r}

sarima.for(vol_reg_ts_log, 13, 0, 1, 2)
```

The above plot illustrated how, based on our model, avocado sales in the Houston area would be expected to remain on the higher end of the trend over the next quarter. This seemed consistent with our research, and in support of our hypothesis.

##Conclusion

Using the Box-Jenkins method, the best possible class for the optimal model was an ARIMA(0,1,2) applied to the log transformed, undifferenced data. The parameter estimates for the ARIMA(0,1,2) proposed by sarima( ) were $\hat\theta_1 = -0.3416$, $\hat\theta_2 = -0.2375$, and a constant of .0028. Both MA coefficient estimates were significant, but the constant was not, so after removing it and analyzing the residual diagnostics it was determined that among all candidates, this model was optimal because:

-No model assumptions were violated. The standardized residuals appeared stationary and the p-values for all q-statistics of the Ljung-Box Test exceeded $\alpha = 0.05$.

-All parameter estimates were significant for $\alpha= 0.05$.

-All information criteria favored this candidate.

Using this final model to forecast avocado sales volume for the Houston area over the next quarter resulted in values that seemed in-line with our research as they were mostly on the higher end of the trend, and seemed slightly upward in nature. While we felt confident about this model, we would like to emphasize that the accuracy of our forecast remains to be seen. It is important that this analysis be revisited frequently as more data becomes available, and that the forecasting model be modified accordingly.

***

##References

*#Avocado*. Instagram. Retrieved from https://www.instagram.com/explore/tags/avocado/?hl=en.

*Avocado Recipes*. Google. Retrieved from https://www.google.com/search?q=avocado+recipe&oq=avocado+re&aqs=chrome.0.69i59j0j69i57j69i60l3.1944j0j7&sourceid=chrome&ie=UTF-8. 

*Commodity: Avocados.* Produce Market Guide. Retrieved from https://www.producemarketguide.com/produce/avocados.

Ferdman, Roberto A. (2015, Jan). *The Rise of the Avocado, America's New Favorite Fruit.* The Washington Post. Retrieved from https://www.washingtonpost.com/news/wonk/wp/2015/01/22/the-sudden-rise-of-the-avocado-americas-new-favorite-fruit/?utm_term=.5187d0527886.

Handwerk, Brian. (2017, Jul). *Holy Guacamole: How the Hass Avocado Conquered the World.* Smithsonian.com. Retrieved from https://www.smithsonianmag.com/science-nature/holy-guacamole-how-hass-avocado-conquered-world-180964250/. 

Karst, Tom. (2018, Jan). *Villita Avocados Investing in Texas Crop.* The Packer. Retrieved from https://www.thepacker.com/article/villita-avocados-investing-texas-crop.

Kiggins, Justin. (2018, Jun). *Avocado Prices: Historical Data on Avocado Prices & Sales Volume in Multiple U.S. Markets.* Retrieved from https://www.kaggle.com/neuromusic/avocado-prices/home.

Knowles, Mike. (2017, Jun). *Why Have Avocados Become So Popular?* Fruit Logistica. Retrieved from http://www.fruitnet.com/eurofruit/article/172578/why-have-avocados-become-so-popular.

*Latest Fruit Market Trending Data. Hass Avocado Board. (2018).* Retrieved from http://www.hassavocadoboard.com/retail/fruit-trending-data.


