extensions [ gis csv ]

globals [ starting-seed year kommuner-list fylker-list farms-list slaughterhouse-list dairy-list checkpoint-list pp-barley pp-oats pp-wheat pp-rye-triticale pp-oilseeds pp-potatoes pp-vegetables pp-fodder-silage pp-other-crops pp-pome-stone-fruit pp-berries pp-other-cattle-meat pp-beef-cow-meat pp-dairy-cow-meat pp-raw-milk pp-pig-meat pp-sheep-meat pp-broiler-meat pp-wool pp-eggs dist-coeff total-imports-beef total-imports-pork total-imports-lamb total-imports-chicken total-imports-eggs total-imports-milk-cream total-imports-yoghurt total-imports-butter total-imports-cheese total-exports-beef total-exports-pork total-exports-lamb total-exports-chicken total-exports-eggs total-exports-milk-cream total-exports-yoghurt total-exports-butter total-exports-cheese production-per-capita-beef production-per-capita-pork production-per-capita-lamb production-per-capita-chicken production-per-capita-eggs production-per-capita-wool production-per-capita-rawmilk cm-cost-beef cm-cost-pork cm-cost-lamb cm-cost-chicken pf-cost-dairy pf-cost-eggs aggregate-production-cm-meat aggregate-production-pf-dairy aggregate-production-pf-eggs emissions-ha-barley emissions-ha-oats emissions-ha-wheat emissions-ha-rye-triticale emissions-ha-oilseeds emissions-ha-potatoes emissions-ha-vegetables emissions-ha-fodder-silage emissions-ha-other-crops emissions-ha-orchards emissions-ha-berries emissions-head-dairy-cows emissions-head-beef-cows emissions-head-other-cattle emissions-head-sheep emissions-head-pigs emissions-head-broilers emissions-head-laying-hens init-num-specialist-cattle-farms init-num-specialist-sheep-farms init-num-specialist-pig-farms init-num-specialist-broiler-farms init-num-specialist-laying-hen-farms init-num-specialist-fodder-silage-farms init-num-specialist-arable-horticulture-farms init-num-combined-cattle-grain-farms init-num-combined-cattle-sheep-farms init-num-other-mixed-farms init-num-no-activity-farms ]

breed [ kommuner kommune ]
breed [ fylker fylke ]
breed [ farms farm ]
breed [ slaughterhouses slaughterhouse ]
breed [ dairies dairy ]
breed [ checkpoints checkpoint ]
breed [ cm-factories cm-factory ]
breed [ pf-factories pf-factory ]
directed-link-breed [ farm-dairy-links farm-dairy-link ]
directed-link-breed [ farm-slaughterhouse-links farm-slaughterhouse-link ]

patches-own [ parent-kommune ]
kommuner-own [ kommune-id fylke-id kommune-name fylke-name population consumption-beef consumption-pork consumption-lamb consumption-chicken consumption-eggs consumption-milk-cream consumption-yoghurt consumption-butter consumption-cheese ]
fylker-own [ fylke-id yield-barley yield-oats yield-wheat yield-rye-triticale yield-oilseeds yield-potatoes yield-vegetables yield-fodder-silage yield-other-crops yield-orchards yield-berries yield-other-cattle-meat yield-beef-cow-meat yield-dairy-cow-meat yield-raw-milk yield-pig-meat yield-sheep-meat yield-broiler-meat yield-wool yield-eggs ]
farms-own [ farm-id farm-type active? kommune-id fylke-id partner-dairy dairy-distance-km partner-slaughterhouse slaughterhouse-distance-km ha-barley ha-oats ha-wheat ha-rye-triticale ha-oilseeds ha-potatoes ha-vegetables ha-fodder-silage ha-other-crops ha-orchards ha-berries num-dairy-cows num-beef-cows num-other-cattle num-sheep num-pigs num-broilers num-laying-hens subsidy-nonlivestock subsidy-livestock subsidy-milk benchmark-income annual-income recent-income current-income annual-emissions current-emissions annual-carbon-tax-liability current-carbon-tax-liability ]
slaughterhouses-own [ slaughterhouse-name min-viable-meat supply-beef supply-pork supply-lamb supply-chicken supply-eggs processed-beef processed-pork processed-lamb processed-chicken processed-eggs wholesale-stock-beef wholesale-stock-pork wholesale-stock-lamb wholesale-stock-chicken wholesale-stock-eggs active? ]
dairies-own[ dairy-name min-viable-rawmilk supply-rawmilk processed-rawmilk wholesale-stock-milk-cream wholesale-stock-yoghurt wholesale-stock-butter wholesale-stock-cheese active? ]
checkpoints-own [ checkpoint-id checkpoint-name checkpoint-type destination imports-beef imports-pork imports-lamb imports-chicken imports-milk-cream imports-yoghurt imports-butter imports-cheese imports-eggs exports-beef exports-pork exports-lamb exports-chicken exports-milk-cream exports-yoghurt exports-butter exports-cheese exports-eggs ]
cm-factories-own [ product-type production-quota wholesale-stock processed-meat factory-emissions ]
pf-factories-own [ product-type production-quota wholesale-stock-milk-cream wholesale-stock-yoghurt wholesale-stock-butter wholesale-stock-cheese wholesale-stock-eggs processed-rawmilk processed-eggs factory-emissions ]

<<<<<<<<<<<<<< SETUP >>>>>>>>>>>>>>>>>>>>>>>>>

to setup
  ca
  clear-all
  file-close-all
  set starting-seed new-seed
  random-seed starting-seed
  set year start-yr
  if param-scenario = "Default" [
    set-params-to-default
  ]
  setup-maps
  setup-kommuner
  setup-fylker
  setup-population
  setup-farms
  setup-slaughterhouses
  setup-dairies
  setup-crop-yields
  setup-animal-yields
  setup-producer-price
  calibrate-distance
  setup-farm-to-processor-links
  setup-checkpoints
  setup-consumption
  setup-trade-records
  setup-per-capita-production-records
  setup-cultured-meat
  setup-biosynthetic-liquid
  setup-emissions
  reset-ticks
end

to setup-maps
  file-close-all
  ; Setup world aesthetics.
  ask patches [ set pcolor white ]
  ; Load the geographical datasets using the approach set out in Wilensky & Rand (2015, p.404-404).
  set kommuner-list gis:load-dataset "Data/NO_AdministrativeBorders/ProcessedData/NO_NetLogoKommuner.geojson"
  set fylker-list gis:load-dataset "Data/NO_AdministrativeBorders/ProcessedData/NO_NetLogoFylker.geojson"
  set slaughterhouse-list gis:load-dataset "Data/NO_Slaughterhouses/ProcessedData/NO_NetLogoSlaughterhouses.geojson"
  set dairy-list gis:load-dataset "Data/NO_Dairies/ProcessedData/NO_NetLogoDairies.geojson"
  if start-yr = 2013 [ set farms-list gis:load-dataset "Data/NO_Farms/ProcessedData/NO_NetLogoFarms2013.geojson" ]
  if start-yr = 2020 [ set farms-list gis:load-dataset "Data/NO_Farms/ProcessedData/NO_NetLogoFarms2020.geojson" ]
  set checkpoint-list gis:load-dataset "Data/NO_BorderCheckpoints/ProcessedData/NO_NetLogoBorderCheckpoints.geojson"
  ; Set the world envelope to the union of all of our dataset's envelopes.
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of kommuner-list) (gis:envelope-of fylker-list) (gis:envelope-of farms-list) (gis:envelope-of slaughterhouse-list) (gis:envelope-of dairy-list) (gis:envelope-of checkpoint-list))
  ; Draw the kommuner and associate patches with the admin units they lie within.
  gis:set-drawing-color 8
  gis:draw kommuner-list 0.5
  ; Draw fylker and set the fill to grey.
  gis:set-drawing-color 7
  gis:draw fylker-list 1
  ask patches gis:intersecting fylker-list [ set pcolor 9 ]
  file-close
end

to setup-kommuner
  file-close-all
  ; One at a time, add kommuner as agents.
  foreach gis:feature-list-of kommuner-list [ current-kommune ->
    let centroid gis:location-of gis:centroid-of current-kommune
    create-kommuner 1  [
      ; Set the kommuner ID and its associated fylker ID.
      set kommune-id gis:property-value current-kommune "KommunerID"
      set fylke-id gis:property-value current-kommune "FylkerID"
      set kommune-name gis:property-value current-kommune "KommunerName"
      set fylke-name gis:property-value current-kommune "FylkerName"
      set population []
      set consumption-beef []
      set consumption-pork []
      set consumption-lamb []
      set consumption-chicken []
      set consumption-eggs []
      set consumption-milk-cream []
      set consumption-yoghurt []
      set consumption-butter []
      set consumption-cheese []
      ; Specify aesthetics.
      set xcor item 0 centroid
      set ycor item 1 centroid
      set color 6
      set shape "circle"
      set size 3
      if hide-kommuner? = TRUE [
        set hidden? TRUE
      ]
    ]
  ]
  ; When reading in CSV files, NetLogo automatically assumes the kommune ID's in the CSV are numeric
  ; rather than character so converts  "0301" to "301". This makes it difficult to match data to the
  ; kommune agent for this kommune. We'll resolve this by changing the agents kommune ID to the
  ; short version. This can be reversed at the end of the setup if now more matching is needed.
  ask kommuner with [ kommune-id = "0301" ] [ set kommune-id "301" ]
  file-close
end

to setup-fylker
  file-close-all
  ; One at a time, add fylker as agents.
  foreach gis:feature-list-of fylker-list [ current-fylke ->
    let centroid gis:location-of gis:centroid-of current-fylke
    create-fylker 1  [
      ; Set the fylke ID.
      set fylke-id gis:property-value current-fylke "FylkerID"
      ; Initialise crop yield lists.
      set yield-barley []
      set yield-oats []
      set yield-wheat []
      set yield-rye-triticale []
      set yield-oilseeds []
      set yield-potatoes []
      set yield-vegetables []
      set yield-fodder-silage []
      set yield-other-crops []
      set yield-orchards []
      set yield-berries []
      set yield-other-cattle-meat []
      set yield-beef-cow-meat []
      set yield-dairy-cow-meat []
      set yield-raw-milk []
      set yield-pig-meat []
      set yield-sheep-meat []
      set yield-broiler-meat []
      set yield-wool []
      set yield-eggs []
      ; Specify aesthetics.
      set xcor item 0 centroid
      set ycor item 1 centroid
      set color 6
      set shape "triangle"
      set size 10
      if hide-fylker? = TRUE [
        set hidden? TRUE
      ]
    ]
  ]
  ; When reading in CSV files, NetLogo automatically assumes the kommune ID's in the CSV are numeric
  ; rather than character so converts  "0301" to "301". This makes it difficult to match data to the
  ; kommune agent for this kommune. We'll resolve this by changing the agents kommune ID to the
  ; short version. This can be reversed at the end of the setup if now more matching is needed.
  ask kommuner with [ kommune-id = "0301" ] [ set kommune-id "301" ]
  file-close
  file-close
end

to setup-population
  file-close-all
  ; Begin by adding the observed population data.
  file-open "Data/NO_Population/ProcessedData/NO_Population.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-kommune item 0 row
    let current-year item 1 row
    let current-population item 2 row

    ; Drop the first sublist as it contains the header rather than any data of relevance & ignore data that
    ; preceeds the simulation start year.
    if current-year != "Year" and current-year >= start-yr [
      ; Identify the kommune that matches the current-kommune ID, and ask it to add the current-year
      ; and current-population as a sublist to the end of its population list.
      ask kommuner with [(word kommune-id) = (word current-kommune)] [
        set population lput list ( current-year ) ( current-population ) population
      ]
    ]

  ]
  file-close

  ;;;;;;;;;;REPLACE WITH SD?????;;;;;;;;;;;;,

  ; Next, add the projected population data, choosing the scenario specified by the interface chooser.
  file-open "Data/NO_Population/ProcessedData/NO_PopulationProj.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-kommune item 0 row
    let current-year item 1 row
    let current-scenario item 2 row
    let current-population item 3 row
    ; We are only interested in data applicable to the chosen scenario.
    if current-scenario = population-growth [
      ; Identify the kommune that matches the current-kommune ID, and ask it to add the current-year
      ; and current-population as a sublist to the end of its population list.
      ask kommuner with [(word kommune-id) = (word current-kommune)] [
        set population lput list ( current-year ) ( current-population ) population
      ]
    ]
  file-close
end

to setup-farms
  if start-yr = 2013 [ set num-farms-to-sim 42437 ]
  if start-yr = 2020 [ set num-farms-to-sim 40382 ]
  file-close-all
  ; One at a time, add ports as agents.
  foreach n-of num-farms-to-sim gis:feature-list-of farms-list [ current-farm ->
    let centroid gis:location-of gis:centroid-of current-farm
    create-farms 1 [
      ; Assign each farm their ID, kommune ID, and details of their activities, plus initialise lists
      ; that will be used to determine the benchmark income they aspire to and their annual income.
      set farm-id gis:property-value current-farm "FarmerID"
      set farm-type gis:property-value current-farm "FarmType"
      set active? TRUE
      set kommune-id gis:property-value current-farm "KommunerID"
      set fylke-id gis:property-value current-farm "FylkerID"
      set ha-barley gis:property-value current-farm "Barley"
      set ha-oats gis:property-value current-farm "Oats"
      set ha-wheat gis:property-value current-farm "Wheat"
      set ha-rye-triticale gis:property-value current-farm "Rye & triticale"
      set ha-oilseeds gis:property-value current-farm "Oilseeds"
      set ha-potatoes gis:property-value current-farm "Potatoes"
      set ha-vegetables gis:property-value current-farm "Vegetables"
      set ha-fodder-silage gis:property-value current-farm "Green fodder & silage"
      set ha-other-crops gis:property-value current-farm "Other crops"
      set ha-orchards gis:property-value current-farm "Orchards"
      set ha-berries gis:property-value current-farm "Berries"
      set num-dairy-cows gis:property-value current-farm "Dairy cows"
      set num-beef-cows gis:property-value current-farm "Beef cows"
      set num-other-cattle gis:property-value current-farm "Other cattle"
      set num-sheep gis:property-value current-farm "Sheep"
      set num-pigs gis:property-value current-farm "Pigs"
      set num-broilers gis:property-value current-farm "Broilers"
      set num-laying-hens gis:property-value current-farm "Laying hens"
      set subsidy-nonlivestock gis:property-value current-farm "Non-livestock subsidy"
      set subsidy-livestock gis:property-value current-farm "Livestock subsidy"
      set subsidy-milk gis:property-value current-farm "Milk subsidy"
      set benchmark-income []

      ;;;WHERE IS THIS COMING FROM??? SD???
      set annual-income []
      set recent-income []
      set current-income 0
      set annual-emissions []
      set current-emissions 0
      set annual-carbon-tax-liability []
      set current-carbon-tax-liability 0


      ; Specify aesthetics.
      set xcor item 0 centroid
      set ycor item 1 centroid
      set color [77 123 106 125]
      set shape "circle"
      set size 1
      if hide-farms? = TRUE [
        set hidden? TRUE
      ]
    ]
  ]
  file-close
  ; Log the initial number of farms of each type to the relevant global variables.
  set init-num-specialist-cattle-farms specialist-cattle-farms
  set init-num-specialist-sheep-farms specialist-sheep-farms
  set init-num-specialist-pig-farms specialist-pig-farms
  set init-num-specialist-broiler-farms specialist-broiler-farms
  set init-num-specialist-laying-hen-farms specialist-laying-hen-farms
  set init-num-specialist-fodder-silage-farms specialist-fodder-silage-farms
  set init-num-specialist-arable-horticulture-farms specialist-arable-horticulture-farms
  set init-num-combined-cattle-grain-farms combined-cattle-grain-farms
  set init-num-combined-cattle-sheep-farms combined-cattle-sheep-farms
  set init-num-other-mixed-farms other-mixed-farms
  set init-num-no-activity-farms no-activity-farms
end

to setup-slaughterhouses
  file-close-all
  ; One at a time, add slaughterhouses as agents.
  foreach gis:feature-list-of slaughterhouse-list [ current-slaughterhouse ->
    let centroid gis:location-of gis:centroid-of current-slaughterhouse
    create-slaughterhouses 1  [
      ; Set the name and the processing capacity. The max processing capacity is set for each animal
      ; type individually. It is the number of slaughters performed in 2020 by the slaughterhouse as
      ; reported by Animalia (2021, p.132), plus a percentage buffer specified by the slaughter-max-
      ; capacity slider. The min-viable-meat threshold is the point at which the slaughterhouse is
      ; no longer considered viable. It is the total meat weight processed in 2020, multiplied by
      ; a slaughter-min-capacity slider value. The wholesale-meat lists are records of the amount of
      ; meat the slaughterhouse have processed in each given year.
      set slaughterhouse-name gis:property-value current-slaughterhouse "Slaughterhouse"
      set min-viable-meat 0
      set supply-beef 0
      set supply-pork 0
      set supply-lamb 0
      set supply-chicken 0
      set supply-eggs 0
      set processed-beef []
      set processed-pork []
      set processed-lamb []
      set processed-chicken []
      set processed-eggs []
      set wholesale-stock-beef 0
      set wholesale-stock-pork 0
      set wholesale-stock-lamb 0
      set wholesale-stock-chicken 0
      set wholesale-stock-eggs 0
      set active? TRUE
      ; Specify aesthetics.
      set xcor item 0 centroid
      set ycor item 1 centroid
      set color black
      set shape "square"
      set size 5
      if hide-slaughterhouses? = TRUE [
        set hidden? TRUE
      ]
    ]
  ]
  file-close
end

to setup-dairies
  file-close-all
  ; One at a time, add dairies as agents.
  foreach gis:feature-list-of dairy-list [ current-dairy ->
    let centroid gis:location-of gis:centroid-of current-dairy
    create-dairies 1  [
      ; Set the name and initialise variables that will be calibrated during the first step to
      ; specify processing capacity and raw milk processing threshold below which the dairy will
      ; no longer be considered viable.
      set dairy-name gis:property-value current-dairy "Dairy"
      set min-viable-rawmilk 0
      set supply-rawmilk 0
      set processed-rawmilk []
      set wholesale-stock-milk-cream 0
      set wholesale-stock-yoghurt 0
      set wholesale-stock-butter 0
      set wholesale-stock-cheese 0
      set active? TRUE
      ; Specify aesthetics.
      set xcor item 0 centroid
      set ycor item 1 centroid
      set color black
      set shape "circle"
      set size 5
      if hide-dairies? = TRUE [
        set hidden? TRUE
      ]
    ]
  ]
  file-close
end

to setup-crop-yields
  file-close-all
  file-open "Data/NO_Yields/ProcessedData/NO_NetLogoCropYield.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-year item 0 row
    ; Drop the first sublist as it contains the header rather than any data of relevance & ignore data that
    ; preceeds the simulation start year.
    if current-year != "Year" and current-year >= start-yr [
      let current-fylker item 1 row
      ; Identify the fylke that matches the current-fylker ID.
      ask fylker with [(word fylke-id) = (word current-fylker)] [
        ; Extract the mean yield and Standard Deviation values for the current crop and fylker.
        let yield-mean item 3 row
        let yield-sd item 4 row
        ; There SD of the green fodder and silage is very high for some fylker. This variability leads to
        ; a lot of farms ceasing operations at some point in the model, yet there the degree of variability
        ; in the data seems suspect. As with the berries, oilseeds, orchards, vegetables, and other crop
        ; categories (which lack sufficient data to assess variability with confidence), we have therefore
        ; decided to not simulate temporal variability in green fodder and silage yields, only spatial
        ; variability. Here we reset the SD for these cases to zero.


        ;;;;;THIS NEEDS TO CHANGE AS PART OF THE SCENARIOS FOR BIOECONOMY
        if item 2 row = "Green fodder & silage" [ set yield-sd 0 ]
        ; Ask this fylke to generate a yield value for the current crop based on the mean and SD.

       ;;;;;THIS NEEDS TO CHANGE AS PART OF THE SCENARIOS FOR BIOECONOMY
        let current-yield precision (random-normal yield-mean yield-sd) 2
        ; If the generated value is more than two standard deviations above or below the mean, we
        ; set the number to the two standard deviations threshold. This prevents negative yield
        ; values which are not possible in the real world and puts bounds on the possible extreme
        ; values. This is reasonable to do in a Western agricultural context where there typically
        ; are upper and lower bounds to viable yields.
        if current-yield < (yield-mean - (yield-sd * 2)) [
          set current-yield yield-mean - (yield-sd * 2)
        ]
        if current-yield > (yield-mean + (yield-sd * 2)) [
          set current-yield yield-mean + (yield-sd * 2)
        ]

        ; Add the generated value to the end of the nested list for the crop of interest.
        if item 2 row = "Barley" [ set yield-barley lput list (current-year) (current-yield) yield-barley ]
        if item 2 row = "Oats" [ set yield-oats lput list (current-year) (current-yield) yield-oats ]
        if item 2 row = "Wheat" [ set yield-wheat lput list (current-year) (current-yield) yield-wheat ]
        if item 2 row = "Rye & triticale" [ set yield-rye-triticale lput list (current-year) (current-yield) yield-rye-triticale ]
        if item 2 row = "Oilseeds" [ set yield-oilseeds lput list (current-year) (current-yield) yield-oilseeds ]
        if item 2 row = "Potatoes" [ set yield-potatoes lput list (current-year) (current-yield) yield-potatoes ]
        if item 2 row = "Vegetables" [ set yield-vegetables lput list (current-year) (current-yield) yield-vegetables ]
        if item 2 row = "Green fodder & silage" [ set yield-fodder-silage lput list (current-year) (current-yield) yield-fodder-silage ]
        if item 2 row = "Other crops" [ set yield-other-crops lput list (current-year) (current-yield) yield-other-crops ]
        if item 2 row = "Orchards" [ set yield-orchards lput list (current-year) (current-yield) yield-orchards ]
        if item 2 row = "Berries" [ set yield-berries lput list (current-year) (current-yield) yield-berries ]
      ]
    ]
  ]
  file-close
end

to setup-animal-yields
  file-close-all
  file-open "Data/NO_Yields/ProcessedData/NO_NetLogoAnimalYield.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-year item 0 row
    ; Drop the first sublist as it contains the header rather than any data of relevance & ignore data that
    ; preceeds the simulation start year.
    if current-year != "Year" and current-year >= start-yr [
      let current-fylker item 1 row
      ; Identify the fylker that matches the current-fylker ID.
      ask fylker with [(word fylke-id) = (word current-fylker)] [
        ; The yield selected depends on whether the user wishes to use constant yield or trend yield trajectories post-2020.

        ;;;;;;THIS IS THE DYNAMIC PART

        let current-yield 0
        if animal-yield-trajectory = "Constant" [ set current-yield item 4 row ]
        if animal-yield-trajectory = "Trend" [ set current-yield item 5 row ]
        ; Ask the fylke to add the yield value to the end of the nested list for the raw agricultural product of interest.
        if item 3 row = "Other cattle meat" [ set yield-other-cattle-meat lput list (current-year) (current-yield) yield-other-cattle-meat ]
        if item 3 row = "Beef cow meat" [ set yield-beef-cow-meat lput list (current-year) (current-yield) yield-beef-cow-meat ]
        if item 3 row = "Dairy cow meat" [ set yield-dairy-cow-meat lput list (current-year) (current-yield) yield-dairy-cow-meat ]
        if item 3 row = "Raw milk" [ set yield-raw-milk lput list (current-year) (current-yield) yield-raw-milk ]
        if item 3 row = "Pig meat" [ set yield-pig-meat lput list (current-year) (current-yield) yield-pig-meat ]
        if item 3 row = "Sheep meat" [ set yield-sheep-meat lput list (current-year) (current-yield) yield-sheep-meat ]
        if item 3 row = "Broiler meat" [ set yield-broiler-meat lput list (current-year) (current-yield) yield-broiler-meat ]
        if item 3 row = "Wool" [ set yield-wool lput list (current-year) (current-yield) yield-wool ]
        if item 3 row = "Eggs" [ set yield-eggs lput list (current-year) (current-yield) yield-eggs ]
      ]
    ]
  ]
  file-close
end

to setup-producer-price
  ; Initialise producer price lists.
  set pp-barley []
  set pp-oats []
  set pp-wheat []
  set pp-rye-triticale []
  set pp-oilseeds []
  set pp-potatoes []
  set pp-vegetables []
  set pp-fodder-silage []
  set pp-other-crops []
  set pp-pome-stone-fruit []
  set pp-berries []
  set pp-other-cattle-meat []
  set pp-beef-cow-meat []
  set pp-dairy-cow-meat []
  set pp-raw-milk []
  set pp-pig-meat []
  set pp-sheep-meat []
  set pp-broiler-meat []
  set pp-wool []
  set pp-eggs []
  ; Read in price data to populate lists.
  file-close-all
  file-open "Data/NO_ProducerPrice/ProcessedData/NO_NetLogoProducerPrice.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-year item 0 row
    let current-price item 2 row
    ; Drop the first sublist as it contains the header rather than any data of relevance & ignore data that
    ; preceeds the simulation start year.
    if current-year != "Year" and current-year >= start-yr [
      if item 1 row = "Barley" [ set pp-barley lput list (current-year) (current-price) pp-barley ]
      if item 1 row = "Oats" [ set pp-oats lput list (current-year) (current-price) pp-oats ]
      if item 1 row = "Wheat" [ set pp-wheat lput list (current-year) (current-price) pp-wheat ]
      if item 1 row = "Rye & triticale" [ set pp-rye-triticale lput list (current-year) (current-price) pp-rye-triticale ]
      if item 1 row = "Oilseeds" [ set pp-oilseeds lput list (current-year) (current-price) pp-oilseeds ]
      if item 1 row = "Potatoes" [ set pp-potatoes lput list (current-year) (current-price) pp-potatoes ]
      if item 1 row = "Vegetables" [ set pp-vegetables lput list (current-year) (current-price) pp-vegetables ]
      if item 1 row = "Green fodder & silage" [ set pp-fodder-silage lput list (current-year) (current-price) pp-fodder-silage ]
      if item 1 row = "Other crops" [ set pp-other-crops lput list (current-year) (current-price) pp-other-crops ]
      if item 1 row = "Pome & stone fruits" [ set pp-pome-stone-fruit lput list (current-year) (current-price) pp-pome-stone-fruit ]
      if item 1 row = "Berries" [ set pp-berries lput list (current-year) (current-price) pp-berries ]
      ; The post-2020 livestock product prices are set seperately so we cease reading them in after 2020.
      if current-year <= 2020 [
        if item 1 row = "Other cattle meat" [ set pp-other-cattle-meat lput list (current-year) (current-price) pp-other-cattle-meat ]
        if item 1 row = "Beef cow meat" [ set pp-beef-cow-meat lput list (current-year) (current-price) pp-beef-cow-meat ]
        if item 1 row = "Dairy cow meat" [ set pp-dairy-cow-meat lput list (current-year) (current-price) pp-dairy-cow-meat ]
        if item 1 row = "Raw milk" [ set pp-raw-milk lput list (current-year) (current-price) pp-raw-milk ]
        if item 1 row = "Pig meat" [ set pp-pig-meat lput list (current-year) (current-price) pp-pig-meat ]
        if item 1 row = "Sheep meat" [ set pp-sheep-meat lput list (current-year) (current-price) pp-sheep-meat ]
        if item 1 row = "Broiler meat" [ set pp-broiler-meat lput list (current-year) (current-price) pp-broiler-meat ]
        if item 1 row = "Wool" [ set pp-wool lput list (current-year) (current-price) pp-wool ]
        if item 1 row = "Eggs" [ set pp-eggs lput list (current-year) (current-price) pp-eggs ]
      ]
    ]
  ]
  file-close
  ; If the price scenario selected calls for prices to be set by users...
  if price-scenario = "User specified" [
    ; The empirical data used to inform the producer price scenarios only takes us to 2020 so we need
    ; to determine values for subsequent years. We do this by assuming constant year-on-year growth
    ; with the rate of growth determined by the `price-growth-product` sliders. It can be between
    ; -5% and 5%.
    let current-year 2021
    loop [
      if current-year > sim-end-yr [ stop ]
      ; Determine the previous year's beef price (which is the same for all cattle types), then calculate
      ; what the current price should be given the slider specified growth, then add it to the pp lists
      ; of the various cattle types.
      let previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-other-cattle-meat
      set previous-pp item 1 item 0 previous-pp
      let current-pp (previous-pp + (previous-pp * (price-growth-beef / 100)))
      set pp-other-cattle-meat lput list (current-year) (current-pp) pp-other-cattle-meat
      set pp-dairy-cow-meat lput list (current-year) (current-pp) pp-dairy-cow-meat
      set pp-beef-cow-meat lput list (current-year) (current-pp) pp-beef-cow-meat
      ; Repeat for pork
      set previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-pig-meat
      set previous-pp item 1 item 0 previous-pp
      set current-pp (previous-pp + (previous-pp * (price-growth-pork / 100)))
      set pp-pig-meat lput list (current-year) (current-pp) pp-pig-meat
      ; Repeat for lamb
      set previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-sheep-meat
      set previous-pp item 1 item 0 previous-pp
      set current-pp (previous-pp + (previous-pp * (price-growth-lamb / 100)))
      set pp-sheep-meat lput list (current-year) (current-pp) pp-sheep-meat
      ; Repeat for chicken
      set previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-broiler-meat
      set previous-pp item 1 item 0 previous-pp
      set current-pp (previous-pp + (previous-pp * (price-growth-chicken / 100)))
      set pp-broiler-meat lput list (current-year) (current-pp) pp-broiler-meat
      ; Repeat for eggs
      set previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-eggs
      set previous-pp item 1 item 0 previous-pp
      set current-pp (previous-pp + (previous-pp * (price-growth-eggs / 100)))
      set pp-eggs lput list (current-year) (current-pp) pp-eggs
      ; Repeat for raw milk
      set previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-raw-milk
      set previous-pp item 1 item 0 previous-pp
      set current-pp (previous-pp + (previous-pp * (price-growth-raw-milk / 100)))
      set pp-raw-milk lput list (current-year) (current-pp) pp-raw-milk
      ; Repeat for wool
      set previous-pp filter [ i -> (current-year - 1) = item 0 i ] pp-wool
      set previous-pp item 1 item 0 previous-pp
      set current-pp (previous-pp + (previous-pp * (price-growth-wool / 100)))
      set pp-wool lput list (current-year) (current-pp) pp-wool
      set current-year current-year + 1
    ]
  ]
  ; If the prices are determined by markets, they will be updated during the go procedure from 2021 onwards.
end

to calibrate-distance
  ; We need to determine roughly how NetLogo distances translate into real world distances. We can do
  ; this by calculating the NetLogo world distance between various pairs of agents, and comparing this
  ; to the known real world distances between those pairs of agents in km. We'll average the conversion
  ; coefficient of five modestly seperated dairies. For converting modest distances, this method appears
  ; pretty good, but performance drops when travelling more than a few hundred km. We'll use this
  ; coefficient in a reporter than will return a distance value in km for specified pairs of agents.
  let actual-distance-a 186.48
  let actual-distance-b 352
  let actual-distance-c 188.6
  let actual-distance-d 161.4
  let actual-distance-e 68.95
  let netlogo-distance-a [ distance one-of dairies with [ dairy-name = "TINE Meieriet Tana" ] ] of one-of dairies with [ dairy-name = "TINE Meieriet Alta" ]
  let netlogo-distance-b [ distance one-of dairies with [ dairy-name = "TINE Meieriet Sandnessjøen" ] ] of one-of dairies with [ dairy-name = "TINE Meieriet Harstad" ]
  let netlogo-distance-c [ distance one-of dairies with [ dairy-name = "TINE Meieriet Sem" ] ] of one-of dairies with [ dairy-name = "Hennig-Olsen Iskremfabrikk" ]
  let netlogo-distance-d [ distance one-of dairies with [ dairy-name = "TINE Meieriet Sem" ] ] of one-of dairies with [ dairy-name = "TINE Meieriet Setesdal" ]
  let netlogo-distance-e [ distance one-of dairies with [ dairy-name = "Synnøve Finden Alvdal" ] ] of one-of dairies with [ dairy-name = "TINE Meieriet Frya" ]
  let coeff-a actual-distance-a / netlogo-distance-a
  let coeff-b actual-distance-b / netlogo-distance-b
  let coeff-c actual-distance-c / netlogo-distance-c
  let coeff-d actual-distance-d / netlogo-distance-d
  let coeff-e actual-distance-e / netlogo-distance-e
  set dist-coeff (coeff-a + coeff-b + coeff-c + coeff-d + coeff-e) / 5
end

to setup-farm-to-processor-links
  ; Dairies.
  ; Ask each farm with dairy cows to identify their nearest dairy as the crow flies. This dairy becomes
  ; its initial partner dairy. We also calculate the distance.
  ask farms with [ num-dairy-cows > 0 ] [
    set partner-dairy min-one-of dairies [ distance myself ]
    create-farm-dairy-link-to partner-dairy [
      tie
      set color [239 213 167 125]
      if hide-farm-dairy-links? = TRUE [ set hidden? TRUE ]
    ]
    set dairy-distance-km (item 0 [link-length] of my-farm-dairy-links) * dist-coeff
  ]
  ; Initialise the dairy min and max raw milk processing capacity by calculating initial milk
  ; production of partner farms and applying the buffers specified by dairy-min-capacity and
  ; dairy-max-capacity.
  ask dairies [
    let raw-milk-supply-initial 0
    ask my-farm-dairy-links [ ask other-end [ set raw-milk-supply-initial raw-milk-supply-initial + farm-production-raw-milk ] ]
    set min-viable-rawmilk (raw-milk-supply-initial / 100) * dairy-min-capacity
  ]
  ; Slaughterhouses.
  ; Ask each farm with livestock to identify their nearest slaughterhouse as the crow flies. This
  ; slaughterhouse becomes its initial partner slaughterhouse. We also calculate the distance.
  ask farms with [ (num-dairy-cows + num-beef-cows + num-other-cattle + num-pigs + num-sheep + num-broilers + num-laying-hens ) > 0 ] [
    set partner-slaughterhouse min-one-of slaughterhouses [ distance myself ]
    create-farm-slaughterhouse-link-to partner-slaughterhouse [
      tie
      set color [204 116 94 125]
      if hide-farm-slaught-links? = TRUE [ set hidden? TRUE ]
    ]
    set slaughterhouse-distance-km (item 0 [link-length] of my-farm-slaughterhouse-links) * dist-coeff
  ]
  ; Initialise the slaughterhouse min and max meat processing capacity by calculating initial
  ; meat production of partner farms and applying the buffers specified by slaughter-min-capacity and
  ; slaughter-max-capacity.
  ask slaughterhouses [
    let meat-supply-initial 0
    ask my-farm-slaughterhouse-links [ ask other-end [ set meat-supply-initial meat-supply-initial + (farm-production-beef + farm-production-lamb + farm-production-pork + farm-production-chicken) ] ]
    set min-viable-meat (meat-supply-initial / 100) * slaughter-min-capacity
  ]
end

to setup-checkpoints
  file-close-all
  ; One at a time, add ports as agents.
  foreach gis:feature-list-of checkpoint-list [ current-checkpoint ->
    let centroid gis:location-of gis:centroid-of current-checkpoint
    create-checkpoints 1 [
      ; Set the ID and name.
      set checkpoint-id gis:property-value current-checkpoint "CheckpointID"
      set checkpoint-name gis:property-value current-checkpoint "CheckpointName"
      set checkpoint-type gis:property-value current-checkpoint "CheckpointType"
      set destination gis:property-value current-checkpoint "Destination"
      set imports-beef 0
      set imports-pork 0
      set imports-lamb 0
      set imports-chicken 0
      set imports-milk-cream 0
      set imports-yoghurt 0
      set imports-butter 0
      set imports-cheese 0
      set imports-eggs 0
      set exports-beef 0
      set exports-pork 0
      set exports-lamb 0
      set exports-chicken 0
      set exports-milk-cream 0
      set exports-yoghurt 0
      set exports-butter 0
      set exports-cheese 0
      set exports-eggs 0
      ; Specify aesthetics.
      set xcor item 0 centroid
      set ycor item 1 centroid
      set color black
      set shape "triangle"
      set size 7
      if hide-checkpoints? = TRUE [
        set hidden? TRUE
      ]
    ]
  ]
  ; We'll also set up globals to record total imports and exports.
;  set total-imports-beef []
;  set total-exports-beef []
  file-close
end

to setup-consumption
  file-close-all
  file-open "Data/NO_FoodConsumption/ProcessedData/NO_ConsumptionWholesale.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-year item 1 row
    let current-product item 0 row
    let current-consumption item 2 row
    ; Drop the first sublist as it contains the header rather than any data of relevance & ignore data that
    ; preceeds the simulation start year.
    if current-year != "Year" and current-year >= start-yr [
      ask kommuner [
        ; Extract the kommune population value for the relevant year.
        let current-year-population filter [ i -> current-year = item 0 i ] population
        set current-year-population item 1 item 0 current-year-population
        ; Populate the relevant consumption list with the per capita consumption value (i.e., current-consumption)
        ; multiplied by the population of the kommune in that year (i.e., current-year-population), converted to tonnes.
        if current-product = "Beef" [ set consumption-beef lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-beef ]
        if current-product = "Pork" [ set consumption-pork lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-pork ]
        if current-product = "Lamb" [ set consumption-lamb lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-lamb ]
        if current-product = "Chicken" [ set consumption-chicken lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-chicken ]
        if current-product = "Eggs" [ set consumption-eggs lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-eggs ]
        if current-product = "Milk & cream" [ set consumption-milk-cream lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-milk-cream ]
        if current-product = "Yoghurt" [ set consumption-yoghurt lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-yoghurt ]
        if current-product = "Butter" [ set consumption-butter lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-butter ]
        if current-product = "Cheese" [ set consumption-cheese lput list (current-year) ((current-consumption * current-year-population) / 1000) consumption-cheese ]
      ]
    ]
  ]
  file-close
  ; The empirical data use to inform the consumption scenarios only takes us to 2020 so we need
  ; to determine values for subsequent years. We do this by assuming constant year-on-year growth
  ; with the rate of growth determined by the `consum-growth-product` sliders. It can be between
  ; -5% and 5%.
  ask kommuner [
    let current-year 2021
    loop [
      if current-year > sim-end-yr [ stop ]
      ; Extract the kommune population value for the previous year.
      let previous-year-population filter [ i -> (current-year - 1) = item 0 i ] population
      set previous-year-population item 1 item 0 previous-year-population
      ; Extract the kommune population value for the current year.
      let current-year-population filter [ i -> current-year = item 0 i ] population
      set current-year-population item 1 item 0 current-year-population
      ; Determine the previous year's per capita beef consumption, then calculate what the current consumption should be given growth.
      let previous-consumption last last consumption-beef / previous-year-population
      let current-consumption (previous-consumption + (previous-consumption * (consum-growth-beef / 100))) * current-year-population
      set consumption-beef lput list (current-year) (current-consumption) consumption-beef
      ; Repeat for pork.
      set previous-consumption last last consumption-pork / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-pork / 100))) * current-year-population
      set consumption-pork lput list (current-year) (current-consumption) consumption-pork
      ; Repeat for lamb.
      set previous-consumption last last consumption-lamb / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-lamb / 100))) * current-year-population
      set consumption-lamb lput list (current-year) (current-consumption) consumption-lamb
      ; Repeat for chicken.
      set previous-consumption last last consumption-chicken / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-chicken / 100))) * current-year-population
      set consumption-chicken lput list (current-year) (current-consumption) consumption-chicken
      ; Repeat for eggs.
      set previous-consumption last last consumption-eggs / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-eggs / 100))) * current-year-population
      set consumption-eggs lput list (current-year) (current-consumption) consumption-eggs
      ; Repeat for milk and cream.
      set previous-consumption last last consumption-milk-cream / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-milk-cream / 100))) * current-year-population
      set consumption-milk-cream lput list (current-year) (current-consumption) consumption-milk-cream
      ; Repeat for yoghurt.
      set previous-consumption last last consumption-yoghurt / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-yoghurt / 100))) * current-year-population
      set consumption-yoghurt lput list (current-year) (current-consumption) consumption-yoghurt
      ; Repeat for butter.
      set previous-consumption last last consumption-butter / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-butter / 100))) * current-year-population
      set consumption-butter lput list (current-year) (current-consumption) consumption-butter
      ; Repeat for Cheese.
      set previous-consumption last last consumption-cheese / previous-year-population
      set current-consumption (previous-consumption + (previous-consumption * (consum-growth-cheese / 100))) * current-year-population
      set consumption-cheese lput list (current-year) (current-consumption) consumption-cheese
      set current-year current-year + 1
    ]
  ]
end

to setup-trade-records
  set total-imports-beef []
  set total-imports-pork []
  set total-imports-lamb []
  set total-imports-chicken []
  set total-imports-eggs []
  set total-imports-milk-cream []
  set total-imports-yoghurt []
  set total-imports-butter []
  set total-imports-cheese []
  set total-exports-beef []
  set total-exports-pork []
  set total-exports-lamb []
  set total-exports-chicken []
  set total-exports-eggs []
  set total-exports-milk-cream []
  set total-exports-yoghurt []
  set total-exports-butter []
  set total-exports-cheese []
end

to setup-per-capita-production-records
  set production-per-capita-beef []
  set production-per-capita-pork []
  set production-per-capita-lamb []
  set production-per-capita-chicken []
  set production-per-capita-eggs []
  set production-per-capita-wool []
  set production-per-capita-rawmilk []
end

to setup-cultured-meat
  file-close-all
  file-open "Data/NO_CulturedProtein/ProcessedData/NO_CulturedMeat.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-scenario item 0 row
    let current-meat item 1 row
    let current-cost item 2 row
    if current-scenario = cm-scenario [
      if current-meat = "Beef" [ set cm-cost-beef current-cost ]
      if current-meat = "Pork" [ set cm-cost-pork current-cost ]
      if current-meat = "Lamb" [ set cm-cost-lamb current-cost ]
      if current-meat = "Chicken" [ set cm-cost-chicken current-cost ]
    ]
  ]
  file-close
end

to setup-biosynthetic-liquid
  file-close-all
  file-open "Data/NO_CulturedProtein/ProcessedData/NO_BiosyntheticDairyAndEggs.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-scenario item 0 row
    let current-product item 1 row
    let current-cost item 2 row
    if current-scenario = pf-scenario [
      if current-product = "Dairy" [ set pf-cost-dairy current-cost ]
      if current-product = "Eggs" [ set pf-cost-eggs current-cost ]
    ]
  ]
  file-close
end

to setup-emissions
  ; Emissions values are given in terms of kg CO2-equiv. per ha or head.
  file-close-all
  file-open "Data/NO_Emissions/ProcessedData/NO_NetLogoEmissions.csv"
  while [ not file-at-end? ] [
    ; Use the CSV extension to grab a line at a time and extract the values.
    let row csv:from-row file-read-line
    let current-activity item 0 row
    let current-value 0
    if emissions-tax-coverage = "Agriculture" [ set current-value item 1 row ]
    if emissions-tax-coverage = "Agriculture & energy" [ set current-value item 2 row ]
    if emissions-tax-coverage = "Agriculture, energy & LULUCF" [ set current-value item 3 row ]
    if current-activity = "Barley" [ set emissions-ha-barley current-value ]
    if current-activity = "Oats" [ set emissions-ha-oats current-value ]
    if current-activity = "Wheat" [ set emissions-ha-wheat current-value ]
    if current-activity = "Rye & triticale" [ set emissions-ha-rye-triticale current-value ]
    if current-activity = "Oilseeds" [ set emissions-ha-oilseeds current-value ]
    if current-activity = "Potatoes" [ set emissions-ha-potatoes current-value ]
    if current-activity = "Vegetables" [ set emissions-ha-vegetables current-value ]
    if current-activity = "Green fodder & silage" [ set emissions-ha-fodder-silage current-value ]
    if current-activity = "Other crops" [ set emissions-ha-other-crops current-value ]
    if current-activity = "Orchards" [ set emissions-ha-orchards current-value ]
    if current-activity = "Berries" [ set emissions-ha-berries current-value ]
    if current-activity = "Dairy cows" [ set emissions-head-dairy-cows current-value ]
    if current-activity = "Beef cows" [ set emissions-head-beef-cows current-value ]
    if current-activity = "Other cattle" [ set emissions-head-other-cattle current-value ]
    if current-activity = "Sheep" [ set emissions-head-sheep current-value ]
    if current-activity = "Pigs" [ set emissions-head-pigs current-value ]
    if current-activity = "Broilers" [ set emissions-head-broilers current-value ]
    if current-activity = "Laying hens" [ set emissions-head-laying-hens current-value ]
  ]
  file-close
end

to set-params-to-default
  set start-yr 2020
  set sim-end-yr 2050
  set num-farms-to-sim 40382
  set animal-yield-trajectory "Constant"
  set population-growth "Medium"
  set farm-income-viability -15
  set slaughter-min-capacity 80
  set max-dist-to-slaughter 230
  set dairy-min-capacity 80
  set max-dist-to-dairy 140
  set price-scenario "Determined by markets"
  set price-baseline-year 2020
  set price-response-ratio 1
  set cease-farming-prob 0.25
  set sim-cm? TRUE
  ; Note that with the cm-init-yr and the pf-init-yr, it will be the next year before production comes
  ; online. This reflects the lag between commisioning and openning such facilities.
  set cm-init-yr 2024
  set cm-factory-capacity 5000
  set cm-scenario "Scenario 7"
  set cm-max-share 53.9
  set sim-pf? TRUE
  set pf-init-yr 2024
  set pf-factory-dairy-capacity 170000
  set pf-factory-egg-capacity 5000
  set pf-scenario "Scenario 2"
  set pf-max-share 53.9
  set efficiency-gain-multiplier 0.95
  set efficiency-step-int-nonmilk 20000
  set efficiency-step-int-milk 680000
  set price-growth-beef 0
  set price-growth-pork 0
  set price-growth-lamb 0
  set price-growth-chicken 0
  set price-growth-eggs 0
  set price-growth-raw-milk 0
  set price-growth-wool 0
  set price-growth-crops 0
  set consum-growth-beef 0
  set consum-growth-pork 0
  set consum-growth-lamb 0
  set consum-growth-chicken 0
  set consum-growth-eggs 0
  set consum-growth-milk-cream 0
  set consum-growth-yoghurt 0
  set consum-growth-butter 0
  set consum-growth-cheese 0
  set emissions-tax-coverage "Agriculture & energy"
  set emissions-cm-meat 4.1
  set emissions-pf-dairy 0.4044
  set emissions-pf-egg 1.56
  set carbon-tax-per-tonne 1500
  set carbon-tax-start-yr 2025
  set cf-required-profit-margin 10
end


@#$#@#$#@
GRAPHICS-WINDOW
210
10
731
532
-1
-1
15.55
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
