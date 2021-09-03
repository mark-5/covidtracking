package CovidReporting::Source::CDC;
use File::Basename qw( dirname );
use File::Spec;
use HTTP::Tiny;
use IO::File;
use JSON::PP qw( decode_json encode_json );
use Moo;
with qw( CovidReporting::Role::Source );

has '+file' => (
    lazy    => 1,
    builder => '_build_file',
);
sub _build_file {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data cdc.csv )
    );
}

sub states {
    my ($self) = @_;
    my $url    = 'https://data.cdc.gov/resource/9mfq-cb36.csv';

    my @data;
    while (1) {
        my $rows = $self->_fetch_csv($url, scalar(@data));
        last if ! @$rows;
        push @data, @$rows;
    }

    return \@data;
}

sub _fetch_csv {
    my ($self, $url, $offset, $limit) = @_;
    $offset ||= 0;
    $limit  ||= 500;

    my $res = HTTP::Tiny->new->get("$url?\$limit=$limit&\$offset=$offset");
    if ( ! $res->{success} ) {
        die "error getting $url: $res->{status} $res->{reason}\n\n$res->{content}";
    }

    return $self->load_csv($res->{content});
}

sub format {
    my ($self, $datum) = @_;
}

sub load {
    my ($self) = @_;
    return $self->countries;
}

sub run {
    my ($self)  = @_;
    my $records = $self->load();
    #local(%LAST);

    for (my $i = 0; $i <= $#{ $records }; $i++) {
        $records->[$i] = $self->format($records->[$i]);
    }

    return $records;
}

1;

__END__

    cdc.state.PA

https://data.cdc.gov/Vaccinations/COVID-19-Vaccination-Demographics-in-the-United-St/km4m-vcsb
    COVID-19 Vaccination Demographics in the United States,National
    daily
   "administered_dose1" : "26388615",
   "administered_dose1_pct" : "53.5",
   "administered_dose1_pct_known" : "14.8",
   "administered_dose1_pct_us" : "0",
   "date" : "2021-08-05T00:00:00.000",
   "demographic_category" : "Ages_18-29_yrs",
   "series_complete_pop_pct" : "44",
   "series_complete_pop_pct_known" : "14.2",
   "series_complete_pop_pct_us" : "0",
   "series_complete_yes" : "21736673"

https://data.cdc.gov/Case-Surveillance/United-States-COVID-19-Cases-and-Deaths-by-State-o/9mfq-cb36
    United States COVID-19 Cases and Deaths by State over Time
    daily
   "consent_cases" : "Not agree",
   "consent_deaths" : "Not agree",
   "created_at" : "2021-01-27T00:00:00.000",
   "new_case" : "646.0",
   "new_death" : "15.0",
   "pnew_case" : "0",
   "pnew_death" : "0",
   "state" : "NE",
   "submission_date" : "2021-01-25T00:00:00.000",
   "tot_cases" : "187923",
   "tot_death" : "1894"

https://data.cdc.gov/Vaccinations/COVID-19-Vaccination-and-Case-Trends-by-Age-Group-/gxj9-t96f
   "_7_day_avg_group_cases_per" : "5.088359065",
   "administered_dose1_pct" : "0.005",
   "agegroupvacc" : "<12 Years",
   "cdc_case_earliest_dt" : "2021-08-03T00:00:00",
   "series_complete_pop_pct" : "0.003"

https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-Jurisdi/unsk-b7fc
    COVID-19 Vaccinations in the United States,Jurisdiction
    daily
   "admin_per_100k" : "113232",
   "admin_per_100k_12plus" : "131702",
   "admin_per_100k_18plus" : "135311",
   "admin_per_100k_65plus" : "170822",
   "administered" : "6520732",
   "administered_12plus" : "6500903",
   "administered_18plus" : "6087919",
   "administered_65plus" : "1439029",
   "administered_dose1_pop_pct" : "60.8",
   "administered_dose1_recip" : "3499965",
   "administered_dose1_recip_1" : "3488261",
   "administered_dose1_recip_2" : "70.7",
   "administered_dose1_recip_3" : "3262948",
   "administered_dose1_recip_4" : "72.5",
   "administered_dose1_recip_5" : "747749",
   "administered_dose1_recip_6" : "88.8",
   "administered_fed_ltc" : "130009",
   "administered_fed_ltc_dose1" : "78151",
   "administered_fed_ltc_dose1_1" : "31777",
   "administered_fed_ltc_dose1_2" : "25750",
   "administered_fed_ltc_dose1_3" : "20624",
   "administered_fed_ltc_residents" : "54816",
   "administered_fed_ltc_staff" : "42996",
   "administered_fed_ltc_unk" : "32197",
   "administered_janssen" : "237188",
   "administered_moderna" : "2666661",
   "administered_pfizer" : "3612870",
   "administered_unk_manuf" : "4013",
   "date" : "2021-08-05T00:00:00.000",
   "dist_per_100k" : "126418",
   "distributed" : "7280095",
   "distributed_janssen" : "340300",
   "distributed_moderna" : "3001320",
   "distributed_per_100k_12plus" : "147488",
   "distributed_per_100k_18plus" : "161808",
   "distributed_per_100k_65plus" : "864196",
   "distributed_pfizer" : "3938475",
   "distributed_unk_manuf" : "0",
   "location" : "CO",
   "mmwr_week" : "31",
   "recip_administered" : "6493990",
   "series_complete_12plus" : "3144591",
   "series_complete_12pluspop" : "63.7",
   "series_complete_18plus" : "2957420",
   "series_complete_18pluspop" : "65.7",
   "series_complete_65plus" : "680926",
   "series_complete_65pluspop" : "80.8",
   "series_complete_fedltc" : "51661",
   "series_complete_fedltc_1" : "22692",
   "series_complete_fedltc_staff" : "17069",
   "series_complete_fedltc_unknown" : "11900",
   "series_complete_janssen" : "233044",
   "series_complete_janssen_12plus" : "233023",
   "series_complete_janssen_18plus" : "231934",
   "series_complete_janssen_65plus" : "21447",
   "series_complete_moderna" : "1247843",
   "series_complete_moderna_12plus" : "1247830",
   "series_complete_moderna_18plus" : "1244272",
   "series_complete_moderna_65plus" : "335686",
   "series_complete_pfizer" : "1670435",
   "series_complete_pfizer_12plus" : "1662488",
   "series_complete_pfizer_18plus" : "1479997",
   "series_complete_pfizer_65plus" : "323373",
   "series_complete_pop_pct" : "54.7",
   "series_complete_unk_manuf" : "1250",
   "series_complete_unk_manuf_1" : "1250",
   "series_complete_unk_manuf_2" : "1217",
   "series_complete_unk_manuf_3" : "420",
   "series_complete_yes" : "3152572"

https://gis.cdc.gov/grasp/covidnet/covid19_3.html
    Laboratory-Confirmed COVID-19-Associated Hospitalizations
        https://gis.cdc.gov/grasp/covid19_3_api/PostPhase03DataTool
        {"appversion":"Public","key":"datadownload","injson":[]}
    CATCHMENT Colorado
    NETWORK EIP
    YEAR 2020-21
    MMWR-YEAR 2020
    MMWR-WEEK 10
    AGE CATEGORY Overall
    SEX Overall
    RACE Overall
    CUMULATIVE RATE 0.1
    WEEKLY RATE 0.1

https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-by-Sex-and-Age/9bhg-hcku
    Provisional COVID-19 Deaths by Sex and Age
   "age_group" : "All Ages",
   "covid_19_deaths" : "606389",
   "data_as_of" : "2021-08-04T00:00:00.000",
   "end_date" : "2021-07-31T00:00:00.000",
   "group" : "By Total",
   "influenza_deaths" : "9211",
   "pneumonia_and_covid_19_deaths" : "298322",
   "pneumonia_deaths" : "547465",
   "pneumonia_influenza_or_covid" : "863452",
   "sex" : "All Sexes",
   "start_date" : "2020-01-01T00:00:00.000",
   "state" : "United States",
   "total_deaths" : "5188518"

https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-Distribution-of-Deaths/pj7m-y5uh
    Provisional COVID-19 Deaths: Distribution of Deaths by Race and Hispanic Origin
   "data_as_of" : "2021-08-04T00:00:00.000",
   "end_week" : "2021-07-31T00:00:00.000",
   "group" : "By Total",
   "hispanic_latino_total" : "110957",
   "indicator" : "Count of COVID-19 deaths",
   "nh_nhopi" : "1138",
   "non_hispanic_american_indian_alaska_native" : "6836",
   "non_hispanic_asian_pacific_islander" : "23063",
   "non_hispanic_black_african_american" : "91784",
   "non_hispanic_more_than_one_race" : "2002",
   "non_hispanic_white" : "368609",
   "start_week" : "2020-01-01T00:00:00.000",
   "state" : "United States",
   "year" : "2020/2021"

https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-by-Race-and-Hispanic-O/ks3g-spdg
    Provisional COVID-19 Deaths by Race and Hispanic Origin, and Age
   "age_group_new" : "All Ages",
   "covid_19_deaths" : "606469",
   "data_as_of" : "2021-08-04T00:00:00.000",
   "end_week" : "2021-07-31T00:00:00.000",
   "influenza_deaths" : "9211",
   "pneumonia_and_covid_19_deaths" : "298374",
   "pneumonia_deaths" : "547507",
   "pneumonia_influenza_or_covid_19" : "863522",
   "race_and_hispanic_origin" : "Total Deaths",
   "start_week" : "2020-01-01T00:00:00.000",
   "state" : "United States",
   "total_deaths" : "5188664"

https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-by-Week-Sex-and-Age/vsak-wrfu
    Provisional COVID-19 Deaths by Week, Sex, and Age
   "age_group" : "All Ages",
   "covid_19_deaths" : "0",
   "data_as_of" : "2021-08-04T00:00:00.000",
   "mmwr_week" : "1",
   "sex" : "All Sex",
   "state" : "United States",
   "total_deaths" : "60166",
   "week_ending_date" : "2020-01-04T00:00:00.000"    

https://www.cdc.gov/nhsn/pdfs/covid19/covid19-NatEst.csv
    state: Two-letter state abbreviation: US
    statename: State name: United States
    collectionDate: Day for which estimate is made: 01APR2020
    InpatBeds_Occ_AnyPat_Est: Hospital inpatient bed occupancy, estimate: 416064
    InpatBeds_Occ_AnyPat_LoCI: Hospital inpatient bed occupancy, lower 95% CI: 380186
    InpatBeds_Occ_AnyPat_UpCI: Hospital inpatient bed occupancy, upper 95% CI: 451942
    InpatBeds_Occ_AnyPat_Est_Avail: Hospital inpatient beds available, estimate: 350555
    InBedsOccAnyPat__Numbeds_Est: Hospital inpatient bed occupancy, percent estimate (percent of inpatient beds): 54.3
    InBedsOccAnyPat__Numbeds_LoCI: Hospital inpatient bed occupancy, lower 95% CI (percent of inpatient beds): 52.5
    InBedsOccAnyPat__Numbeds_UpCI: Hospital inpatient bed occupancy, upper 95% CI (percent of inpatient beds): 56.0
    InpatBeds_Occ_COVID_Est: Number of patients in an inpatient care location who have suspected or confirmed COVID-19,  estimate: 75104
    InpatBeds_Occ_COVID_LoCI: Number of patients in an inpatient care location who have suspected or confirmed COVID-19, lower 95% CI: 66243
    InpatBeds_Occ_COVID_UpCI: Number of patients in an inpatient care location who have suspected or confirmed COVID-19, upper 95% CI: 83964
    InBedsOccCOVID__Numbeds_Est: Number of patients in an inpatient care location who have suspected or confirmed COVID-19, percent estimate (percent of inpatient beds): 9.8
    InBedsOccCOVID__Numbeds_LoCI: Number of patients in an inpatient care location who have suspected or confirmed COVID-19, lower 95% CI (percent of inpatient beds): 8.6
    InBedsOccCOVID__Numbeds_UpCI: Number of patients in an inpatient care location who have suspected or confirmed COVID-19, upper 95% CI (percent of inpatient beds): 11.0
    ICUBeds_Occ_AnyPat_Est: ICU bed occupancy, estimate: 66369
    ICUBeds_Occ_AnyPat_LoCI: ICU bed occupancy, lower 95% CI: 56770
    ICUBeds_Occ_AnyPat_UpCI: ICU bed occupancy, upper 95% CI: 75968
    ICUBeds_Occ_AnyPat_Est_Avail: ICU beds available, estimate: 45110
    ICUBedsOccAnyPat__N_ICUBeds_Est: ICU bed occupancy, percent estimate (percent of ICU beds): 59.5
    ICUBedsOccAnyPat__N_ICUBeds_LoCI: ICU bed occupancy, lower 95% CI (percent of ICU beds): 55.8
    ICUBedsOccAnyPat__N_ICUBeds_UpCI: ICU bed occupancy, upper 95% CI (percent of ICU beds): 63.2
    Notes: This file contains National and State representative estimates from the CDC National Healthcare Safety Network (NHSN).

https://healthdata.gov/Hospital/COVID-19-Reported-Patient-Impact-and-Hospital-Capa/g62h-syeh
    COVID-19 Reported Patient Impact and Hospital Capacity by State Timeseries
    daily
   "adult_icu_bed_covid_utilization_coverage" : "3",
   "adult_icu_bed_covid_utilization_denominator" : "0",
   "adult_icu_bed_covid_utilization_numerator" : "0",
   "adult_icu_bed_utilization_coverage" : "3",
   "adult_icu_bed_utilization_denominator" : "0",
   "adult_icu_bed_utilization_numerator" : "0",
   "critical_staffing_shortage_anticipated_within_week_no" : "1",
   "critical_staffing_shortage_anticipated_within_week_not_reported" : "55",
   "critical_staffing_shortage_anticipated_within_week_yes" : "1",
   "critical_staffing_shortage_today_no" : "1",
   "critical_staffing_shortage_today_not_reported" : "55",
   "critical_staffing_shortage_today_yes" : "1",
   "date" : "2020-07-27T00:00:00.000",
   "deaths_covid" : "0",
   "deaths_covid_coverage" : "2",
   "hospital_onset_covid" : "0",
   "hospital_onset_covid_coverage" : "4",
   "inpatient_bed_covid_utilization" : "0.06060606060606061",
   "inpatient_bed_covid_utilization_coverage" : "54",
   "inpatient_bed_covid_utilization_denominator" : "8118",
   "inpatient_bed_covid_utilization_numerator" : "492",
   "inpatient_beds" : "8118",
   "inpatient_beds_coverage" : "54",
   "inpatient_beds_used" : "4245",
   "inpatient_beds_used_coverage" : "57",
   "inpatient_beds_used_covid" : "514",
   "inpatient_beds_used_covid_coverage" : "56",
   "inpatient_beds_utilization" : "0.49507267799950727",
   "inpatient_beds_utilization_coverage" : "54",
   "inpatient_beds_utilization_denominator" : "8118",
   "inpatient_beds_utilization_numerator" : "4019",
   "percent_of_inpatients_with_covid" : "0.12185870080606923",
   "percent_of_inpatients_with_covid_coverage" : "56",
   "percent_of_inpatients_with_covid_denominator" : "4218",
   "percent_of_inpatients_with_covid_numerator" : "514",
   "previous_day_admission_adult_covid_confirmed_18_19_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_20_29_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_30_39_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_40_49_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_50_59_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_60_69_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_70_79_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_80_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_coverage" : "0",
   "previous_day_admission_adult_covid_confirmed_unknown_coverage" : "0",
   "previous_day_admission_adult_covid_suspected" : "0",
   "previous_day_admission_adult_covid_suspected_18_19_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_20_29_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_30_39_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_40_49_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_50_59_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_60_69_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_70_79_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_80_coverage" : "0",
   "previous_day_admission_adult_covid_suspected_coverage" : "1",
   "previous_day_admission_adult_covid_suspected_unknown" : "0",
   "previous_day_admission_adult_covid_suspected_unknown_coverage" : "1",
   "previous_day_admission_pediatric_covid_confirmed_coverage" : "0",
   "previous_day_admission_pediatric_covid_suspected" : "5",
   "previous_day_admission_pediatric_covid_suspected_coverage" : "1",
   "staffed_adult_icu_bed_occupancy" : "0",
   "staffed_adult_icu_bed_occupancy_coverage" : "3",
   "staffed_icu_adult_patients_confirmed_and_suspected_covid" : "0",
   "staffed_icu_adult_patients_confirmed_and_suspected_covid_coverage" : "3",
   "staffed_icu_adult_patients_confirmed_covid" : "0",
   "staffed_icu_adult_patients_confirmed_covid_coverage" : "3",
   "state" : "PR",
   "total_adult_patients_hospitalized_confirmed_and_suspected_covid" : "0",
   "total_adult_patients_hospitalized_confirmed_and_suspected_covid_coverage" : "3",
   "total_adult_patients_hospitalized_confirmed_covid" : "0",
   "total_adult_patients_hospitalized_confirmed_covid_coverage" : "2",
   "total_pediatric_patients_hospitalized_confirmed_and_suspected_covid" : "5",
   "total_pediatric_patients_hospitalized_confirmed_and_suspected_covid_coverage" : "3",
   "total_pediatric_patients_hospitalized_confirmed_covid" : "0",
   "total_pediatric_patients_hospitalized_confirmed_covid_coverage" : "2",
   "total_staffed_adult_icu_beds" : "0",
   "total_staffed_adult_icu_beds_coverage" : "3"       

https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-by-Place-of-Death-and-/4va6-ph5s
    Provisional COVID-19 Deaths by Place of Death and Age
   "age_group" : "All Ages",
   "covid_19_deaths" : "610424",
   "data_as_of" : "2021-08-11T00:00:00.000",
   "end_week" : "2021-08-07T00:00:00.000",
   "group" : "By Total",
   "hhs_region" : "0",
   "influenza_deaths" : "9223",
   "place_of_death" : "Total - All Places of Death",
   "pneumonia" : "552535",
   "pneumonia_and_covid" : "300592",
   "pneumonia_influenza_or_covid" : "870297",
   "start_week" : "2020-01-01T00:00:00.000",
   "state" : "United States",
   "total_deaths" : "5250104"

https://data.cdc.gov/NCHS/Provisional-Death-Counts-for-Influenza-Pneumonia-a/ynw2-4viq
    Provisional Death Counts for Influenza, Pneumonia, and COVID-19
   "age_group" : "All Ages",
   "covid_19_deaths" : "0",
   "data_as_of" : "08/05/2021",
   "end_week" : "01/04/2020",
   "group" : "By Week",
   "indicator" : "Week-ending",
   "influenza_deaths" : "432",
   "jurisdiction" : "United States",
   "mmwrweek" : "1",
   "mmwryear" : "2020",
   "pneumonia_deaths" : "4102",
   "pneumonia_influenza_or_covid" : "4534",
   "pneumonia_or_influenza" : "4534",
   "start_week" : "12/29/2019",
   "total_deaths" : "60033",
   "week_ending_date" : "2020-01-04T00:00:00.000"    

https://data.cdc.gov/NCHS/Conditions-Contributing-to-COVID-19-Deaths-by-Stat/hk9y-quqm
    Conditions Contributing to COVID-19 Deaths, by State and Age
   "age_group" : "0-24",
   "condition" : "Influenza and pneumonia",
   "condition_group" : "Respiratory diseases",
   "covid_19_deaths" : "465",
   "data_as_of" : "2021-08-10T00:00:00.000",
   "end_date" : "2021-08-07T00:00:00.000",
   "group" : "By Total",
   "icd10_codes" : "J09-J18",
   "number_of_mentions" : "485",
   "start_date" : "2020-01-01T00:00:00.000",
   "state" : "United States"

https://healthdata.gov/dataset/COVID-19-Diagnostic-Laboratory-Testing-PCR-Testing/j8mb-icvb
    COVID-19 Diagnostic Laboratory Testing (PCR Testing) Time Series
    daily
   "date" : "2020-03-01T00:00:00.000",
   "fema_region" : "Region 4",
   "new_results_reported" : "96",
   "overall_outcome" : "Negative",
   "state" : "AL",
   "state_fips" : "01",
   "state_name" : "Alabama",
   "total_results_reported" : "96"    

https://data.cdc.gov/Laboratory-Surveillance/Nationwide-Commercial-Laboratory-Seroprevalence-Su/d2tw-32xv
    Nationwide Commercial Laboratory Seroprevalence Survey
   "all_age_sex_strata_had_at" : false,
   "catchment_area_description" : "Statewide",
   "catchment_fips_code" : "Statewide",
   "catchment_population" : "738516",
   "ci_flag_18_49_prevalence" : "1",
   "ci_flag_50_64_prevalence" : "2",
   "ci_flag_cumulative_prevalence" : "1",
   "ci_flag_female_prevalence" : "1",
   "ci_flag_male_prevalence" : "2",
   "date_range_of_specimen" : "Aug 6 - Aug 11, 2020",
   "estimated_cum_infections_count" : "2216",
   "estimated_cum_infections_lower_ci" : "0",
   "estimated_cum_infections_upper_ci" : "8271",
   "lower_ci_18_49_prevalence" : "0",
   "lower_ci_50_64_prevalence" : "0",
   "lower_ci_cumulative_prevalence" : "0",
   "lower_ci_female_prevalence" : "0",
   "lower_ci_male_prevalence" : "0",
   "n_0_17_prevalence" : "5",
   "n_18_49_prevalence" : "81",
   "n_50_64_prevalence" : "83",
   "n_65_prevalence" : "73",
   "n_cumulative_prevalence" : "242",
   "n_female_prevalence" : "154",
   "n_male_prevalence" : "88",
   "rate_0_17_prevalence" : "777",
   "rate_18_49_prevalence" : "0.7",
   "rate_50_64_prevalence" : "0",
   "rate_65_prevalence" : "777",
   "rate_cumulative_prevalence" : "0.3",
   "rate_female_prevalence" : "0.7",
   "rate_male_prevalence" : "0",
   "round" : "1",
   "site" : "AK",
   "site_large_ci_flag" : true,
   "upper_ci_18_49_prevalence" : "2.23",
   "upper_ci_50_64_prevalence" : "4.35",
   "upper_ci_cumulative_prevalence" : "1.12",
   "upper_ci_female_prevalence" : "2.35",
   "upper_ci_male_prevalence" : "4.11"   

https://github.com/owid/covid-19-data/blob/master/public/data/owid-covid-data.csv
    iso_code
    continent
    location
    date
    total_cases
    new_cases
    new_cases_smoothed
    total_deaths
    new_deaths
    new_deaths_smoothed
    total_cases_per_million
    new_cases_per_million
    new_cases_smoothed_per_million
    total_deaths_per_million
    new_deaths_per_million
    new_deaths_smoothed_per_million
    reproduction_rate
    icu_patients
    icu_patients_per_million
    hosp_patients
    hosp_patients_per_million
    weekly_icu_admissions
    weekly_icu_admissions_per_million
    weekly_hosp_admissions
    weekly_hosp_admissions_per_million
    new_tests
    total_tests
    total_tests_per_thousand
    new_tests_per_thousand
    new_tests_smoothed
    new_tests_smoothed_per_thousand
    positive_rate
    tests_per_case
    tests_units
    total_vaccinations
    people_vaccinated
    people_fully_vaccinated
    total_boosters
    new_vaccinations
    new_vaccinations_smoothed
    total_vaccinations_per_hundred
    people_vaccinated_per_hundred
    people_fully_vaccinated_per_hundred
    total_boosters_per_hundred
    new_vaccinations_smoothed_per_million
    stringency_index
    population
    population_density
    median_age
    aged_65_older
    aged_70_older
    gdp_per_capita
    extreme_poverty
    cardiovasc_death_rate
    diabetes_prevalence
    female_smokers
    male_smokers
    handwashing_facilities
    hospital_beds_per_thousand
    life_expectancy
    human_development_index
    excess_mortality

https://www2.census.gov/programs-surveys/popest/tables/2010-2019/state/asrh/sc-est2019-agesex-civ.csv


deaths by age
    https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-by-Week-Sex-and-Age/vsak-wrfu
        weekly data
        covid deaths only
        no state
    https://data.cdc.gov/NCHS/Provisional-COVID-19-Deaths-by-Sex-and-Age/9bhg-hcku
        only monthly data
    https://data.cdc.gov/NCHS/Provisional-Death-Counts-for-Influenza-Pneumonia-a/ynw2-4viq
        weekly
        no august data
