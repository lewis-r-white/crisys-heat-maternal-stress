## Creating Clean Stress Surveys

# Load necessary libraries
library(readxl)     # reading Excel files
library(tidyverse)      # data manipulation
library(labelled)   # labeling columns 
library(here) # file paths
library(haven)


# Importing Birth Time Data 
delivery_date <- read_csv(here("data", "GRAPHS_datdeliv_vname.csv"))

# Import BMI data
graphs_bmi_data <- read_csv(here("data", "alldata_clean_for_bw_19May08.csv")) %>%
  dplyr::select(mstudyid, bmi)



# Importing data from Excel ----
stress_NLE <- read_dta(here("data", "Stress_NLE.dta"))

# acquire length of gestational period
NLE_covariates <- stress_NLE %>%
  dplyr::select(mstudyid, GESTAGE_DAYS, married, wealthindex, dob, age, medlev, fan, pregchn) %>%
  rename(gestage_days = GESTAGE_DAYS)

crisis_data <- read_excel(here("data", "CAL_stress.xlsx"), sheet = "Crisis")
stress_data <- read_excel(here("data", "CAL_stress.xlsx"), sheet = "Pss")



## Recoding crisis data so b question is NA when a indicates event did not occur / NA response ----

### LET 3 contiunue to represent NA in the data 

crisis_recode_short_form <- crisis_data %>%
  mutate(survey_date = lubridate::ymd(quessetd)) %>%
  
  mutate(
    # Replace `9` with 3 for all columns starting with "a"
    across(matches("^a\\d+$"), ~ ifelse(. == 9, 3, .)),
    
    # Step 2: Iterate over the "a" and "b" pairs to apply the second rule
    across(matches("^b\\d+$"), ~ {
      # Extract the column number from the "b" column name
      col_num <- gsub("^b", "", cur_column())
      # Get the corresponding "a" column
      a_col <- paste0("a", col_num)
      # Make "b" value NA if "a" is 0 or NA
      ifelse(get(a_col) %in% c(0, 3), 3, .)
    })
  )


# Developing NLE score ----

crisis_recode_short_form <- crisis_recode_short_form %>%
  
  # replace 3 with NA to reflect what skip logic would have done
  # mutate(across(matches("^b\\d+$"), ~ replace(., . == 3, NA))) %>%
  
  # Calculate negative perception counts based on "b" columns
  
  # CHANGES FROM SAS CODE: REMOVED A1, A4, A72 as positive events
  mutate(
    fin_events = rowSums(dplyr::select(., a3, a6, a9, a14) == 1, na.rm = TRUE),
    crifinneg = rowSums(dplyr::select(., b3, b6, b9, b14) == 1, na.rm = TRUE),
    fin_nds = ifelse(crifinneg > 0, 1, 0),
    
    leg_events = rowSums(dplyr::select(., a17, a18) == 1, na.rm = TRUE),
    crilegalneg = rowSums(dplyr::select(., b17, b18) == 1, na.rm = TRUE),
    leg_nds = ifelse(crilegalneg > 0, 1, 0),
    
    car_events = rowSums(dplyr::select(.,  a73, a75) == 1, na.rm = TRUE),
    cricareerneg = rowSums(dplyr::select(., b73, b75) == 1, na.rm = TRUE),
    car_nds = ifelse(cricareerneg > 0, 1, 0),
    
    rel_events = rowSums(dplyr::select(., a29, a31, a32, a36) == 1, na.rm = TRUE),
    crirelneg = rowSums(dplyr::select(., b29, b31, b32, b36) == 1, na.rm = TRUE),
    rel_nds = ifelse(crirelneg > 0, 1, 0),
    
    homesf_events = rowSums(dplyr::select(., a39) == 1, na.rm = TRUE),
    crihomesafeneg = rowSums(dplyr::select(., b39) == 1, na.rm = TRUE),
    homesf_nds = ifelse(crihomesafeneg > 0, 1, 0),
    
    neighsf_events = rowSums(dplyr::select(.,  a43, a48) == 1, na.rm = TRUE),
    crineighsafeneg = rowSums(dplyr::select(., b43, b48) == 1, na.rm = TRUE),
    neighsf_nds = ifelse(crineighsafeneg > 0, 1, 0),
    
    ## SHORT FORM COMBINES MEDICAL SELF AND MEDICAL OTHER TO JUST MEDICAL 
    med_events = rowSums(dplyr::select(., a55, a57) == 1, na.rm = TRUE),
    crimedneg = rowSums(dplyr::select(., b55, b57) == 1, na.rm = TRUE),
    med_nds = ifelse(crimedneg > 0, 1, 0),
    
    home_events = rowSums(dplyr::select(., a62, a13) == 1, na.rm = TRUE),
    crihomeneg = rowSums(dplyr::select(., b62, b13) == 1, na.rm = TRUE),
    home_nds = ifelse(crihomeneg > 0, 1, 0),
    
    prej_events = rowSums(dplyr::select(., a66, a68) == 1, na.rm = TRUE),
    criprejneg = rowSums(dplyr::select(., b66, b68) == 1, na.rm = TRUE),
    prej_nds = ifelse(criprejneg > 0, 1, 0),
    
    auth_events = rowSums(dplyr::select(., a74) == 1, na.rm = TRUE),
    criauthneg = rowSums(dplyr::select(., b74) == 1, na.rm = TRUE),
    auth_nds = ifelse(criauthneg > 0, 1, 0),
    
    # Other specific negative events
    oth_events = rowSums(dplyr::select(., a26, a51) == 1, na.rm = TRUE),
    cricomneg = ifelse(b26 == 1, 1, 0),
    cripdrugneg = ifelse(b51 == 1, 1, 0),
    criothneg = rowSums(dplyr::select(., cricomneg, cripdrugneg) == 1, na.rm = TRUE),
    oth_nds = ifelse(criothneg > 0, 1, 0)
  ) %>%
  
  # Summing across all domain scores
  mutate(
    total_events = rowSums(dplyr::select(., fin_events, leg_events, car_events, rel_events, homesf_events, neighsf_events,
                                         med_events, home_events, prej_events, auth_events, oth_events), 
                           na.rm = TRUE),
    
    total_negative_responses = rowSums(dplyr::select(., crifinneg, crilegalneg, cricareerneg, crirelneg, crihomesafeneg, crineighsafeneg, 
                                                     crimedneg, crihomeneg, criprejneg, criauthneg, criothneg), 
                                       na.rm = TRUE),
    
    sum_nds = rowSums(dplyr::select(., fin_nds, leg_nds, car_nds, rel_nds, homesf_nds, neighsf_nds, 
                                    med_nds, home_nds, prej_nds, auth_nds, oth_nds), 
                      na.rm = TRUE)
  ) %>%
  
  # whether event was experienced 
  mutate(
    experienced_auth = ifelse(auth_events > 0, 1, 0),
    experienced_fin = ifelse(fin_events > 0, 1, 0),
    experienced_leg = ifelse(leg_events > 0, 1, 0),
    experienced_car = ifelse(car_events > 0, 1, 0),
    experienced_rel = ifelse(rel_events > 0, 1, 0),
    experienced_homesf = ifelse(homesf_events > 0, 1, 0),
    experienced_neighsf = ifelse(neighsf_events > 0, 1, 0),
    experienced_med = ifelse(med_events > 0, 1, 0),
    experienced_home = ifelse(home_events > 0, 1, 0),
    experienced_prej = ifelse(prej_events > 0, 1, 0),
    experienced_oth = ifelse(oth_events > 0, 1, 0)
  ) %>%
  
  # Change NDS to no event if no event in the domain was experienced (essentially add NA for negative event if event didn't occur)
  mutate(
    auth_nds = ifelse(experienced_auth == 1, auth_nds, "No Event"),
    fin_nds = ifelse(experienced_fin == 1, fin_nds, "No Event"),
    leg_nds = ifelse(experienced_leg == 1, leg_nds, "No Event"),
    car_nds = ifelse(experienced_car == 1, car_nds, "No Event"),
    rel_nds = ifelse(experienced_rel == 1, rel_nds, "No Event"),
    homesf_nds = ifelse(experienced_homesf == 1, homesf_nds, "No Event"),
    neighsf_nds = ifelse(experienced_neighsf == 1, neighsf_nds, "No Event"),
    med_nds = ifelse(experienced_med == 1, med_nds, "No Event"),
    home_nds = ifelse(experienced_home == 1, home_nds, "No Event"),
    prej_nds = ifelse(experienced_prej == 1, prej_nds, "No Event"),
    oth_nds = ifelse(experienced_oth == 1, oth_nds, "No Event")
  ) %>%
  
  # change #negative events expeirenced to "no event" if no event in the domain was experienced 
  mutate(
    criauthneg = ifelse(experienced_auth == 1, criauthneg, "No Event"),
    crifinneg = ifelse(experienced_fin == 1, crifinneg, "No Event"),
    crilegalneg = ifelse(experienced_leg == 1, crilegalneg, "No Event"),
    cricareerneg = ifelse(experienced_car == 1, cricareerneg, "No Event"),
    crirelneg = ifelse(experienced_rel == 1, crirelneg, "No Event"),
    crihomesafeneg = ifelse(experienced_homesf == 1, crihomesafeneg, "No Event"),
    crineighsafeneg = ifelse(experienced_neighsf == 1, crineighsafeneg, "No Event"),
    crimedneg = ifelse(experienced_med == 1, crimedneg, "No Event"),
    crihomeneg = ifelse(experienced_home == 1, crihomeneg, "No Event"),
    criprejneg = ifelse(experienced_prej == 1, criprejneg, "No Event"),
    criothneg = ifelse(experienced_oth == 1, criothneg, "No Event")
  ) %>%
  
  # recategorize domain specific number of negative events to binary to explore top category contributors to sum_nds score 
  mutate(
    # --- Safe numeric copies of the count variables (NA if "No Event" or non-numeric) ---
    crifinneg_num = suppressWarnings(as.integer(as.character(crifinneg))),
    crirelneg_num = suppressWarnings(as.integer(as.character(crirelneg))),
    home_nds_chr  = as.character(home_nds)) %>%
    
  mutate(
    # Resilience score based on total events and total negative responses
    resilience_score = ifelse(total_events > 0, 1 - (total_negative_responses / total_events), NA)
  ) %>%
  
  #recateogrize NDS to low, moderate, high
  mutate(sum_nds_category = factor(
    case_when(sum_nds <= 2 ~ "low",
              sum_nds >= 3 & sum_nds <= 5 ~ "moderate",
              sum_nds >= 6 ~ "high"),
    levels = c("low", "moderate", "high"),
    ordered = TRUE
  )) %>%
  
  ## categorize sum nds at 3rd quartile high vs low
  mutate(
    sum_nds_q3_dichotomized = ifelse(sum_nds < 5, "low", "high"),
    sum_nds_q3_dichotomized = factor(sum_nds_q3_dichotomized, levels = c("low", "high")) 
  ) %>%
  
  
  # add delivery date
  left_join(delivery_date) %>% 
  
  # calculate difference in time between delivery and survey date
  mutate(diffdays = difftime(quessetd, datdeliv, units = "days")) %>%
  
  # ## ASSUMPTION: If questionnaire date and delivery date are the same, assuming participant responded to survey before going into labor
  mutate(survey_pre_post_birth = ifelse(diffdays > 0, "post_delivery", "pre_delivery"))  %>%
  
  # Add in gestation period
  left_join(NLE_covariates) %>%
  
  # add in BMI var
  left_join(graphs_bmi_data) %>%
  
  # add date of conception
  mutate(date_conception = datdeliv - gestage_days) %>%
  
  mutate(
    # gestational age in days at the time of survey
    gestage_at_survey = gestage_days + as.numeric(difftime(quessetd, datdeliv, units = "days")),
    term_at_survey_gestage = case_when(
      gestage_at_survey > 280  ~ "post_partum",
      gestage_at_survey >= 196 ~ "third_trimester",
      gestage_at_survey >= 98  ~ "second_trimester",
      gestage_at_survey >= 0   ~ "first_trimester",
      gestage_at_survey < 0    ~ "pre_conception"
    )
  ) 



# Setting up labels for clarity
var_label(crisis_recode_short_form$criauthneg) <- "Sum of prehome authority negative events"
var_label(crisis_recode_short_form$cricareerneg) <- "Sum of prehome career negative events"
var_label(crisis_recode_short_form$crifinneg) <- "Sum of prehome financial negative events"
var_label(crisis_recode_short_form$crihomeneg) <- "Sum of prehome home negative events"
var_label(crisis_recode_short_form$crihomesafeneg) <- "Sum of prehome home safety negative events"
var_label(crisis_recode_short_form$crilegalneg) <- "Sum of prehome legal negative events"
var_label(crisis_recode_short_form$crimedneg) <- "Sum of prehome medical issues negative events"
var_label(crisis_recode_short_form$crineighsafeneg) <- "Sum of prehome neighborhood safety negative events"
var_label(crisis_recode_short_form$crirelneg) <- "Sum of prehome relationship negative events"
var_label(crisis_recode_short_form$criprejneg) <- "Sum of prehome prejudice negative events"

var_label(crisis_recode_short_form$auth_nds) <- "Prehome authority negative domain score if ANY neg response"
var_label(crisis_recode_short_form$car_nds) <- "Prehome career negative domain score if ANY neg response"
var_label(crisis_recode_short_form$fin_nds) <- "Prehome financial negative domain score if ANY neg response"
var_label(crisis_recode_short_form$home_nds) <- "Prehome home negative domain score if ANY neg response"
var_label(crisis_recode_short_form$homesf_nds) <- "Prehome home safety negative domain score if ANY neg response"
var_label(crisis_recode_short_form$leg_nds) <- "Prehome legal negative domain score if ANY neg response"
var_label(crisis_recode_short_form$med_nds) <- "Prehome medical issues negative domain score if ANY neg response"
var_label(crisis_recode_short_form$neighsf_nds) <- "Prehome neighborhood safety negative domain score if ANY neg response"
var_label(crisis_recode_short_form$rel_nds) <- "Prehome relationship negative domain score if ANY neg response"
var_label(crisis_recode_short_form$prej_nds) <- "Prehome prejudice negative domain score if ANY neg response"

