library(shiny)
source("../scripts/core.R",  local = TRUE)$value

# Define UI for data download app ----
ui <- fluidPage(

  # App title ----
  titlePanel("Drug Sensitivity Predictions for CCLE Cell Lines"),  
  br(),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # # Input: Choose dataset ----
      fluidRow(
        column(10,
               h4("Select Cancer/Tumor Type"),
               )
      ),
      selectInput('in1_tt', 'Choose a tumor type of interest to filter sensitivity predictions by:', get_tumor_types(), multiple=FALSE, selectize=FALSE, selected = get_tumor_types()[1] ),  
      
      fluidRow(
        column(10,
               h4("Select Compound"),
        )
      ),
      selectInput('in2_cp', 'Choose a drug of interest to query sensitivity predictions:', "", multiple=FALSE, selectize=TRUE), 
      
      # Button
      downloadButton("downloadData", "Download")
    ),
  # Main panel for displaying outputs ----
    mainPanel(
      fluidRow(
        column(
          tableOutput("table"), width = 6)
      ),
      width = 8
    )
  )
)

# Define server logic to display and download selected file ----
server <- function(input, output, session) {
  # source("../scripts/core.R",  local = TRUE)$value

  predictions_list <- reactive({
    withProgress(message = 'Loading...', value = 0, {
      get_predictions("../data/")
    }
  )})
  # Combine the selected variables into a new data frame
  observeEvent(eventExpr=input$in1_tt,ignoreInit = F, {
    selectedData <- reactive({
    predictions_list()[[c(input$in1_tt)]]
    })
    
    outVar = reactive({
      unique(names(selectedData()))
    })
    
    observe({
      updateSelectInput(session, "in2_cp", 
                        choices = outVar() 
      ) 
      })

    observeEvent(eventExpr=input$in2_cp,ignoreInit = F, {
      outData_full <- reactive({
        selectedData()[[c(input$in2_cp)]]
      })
      outData <- reactive({
        temp <- as.data.frame(outData_full())
        temp1 <- temp[,-c(1:3),drop=T]
        colnames(temp1)[3:5]<- c("TCGA_tumor_type_code", "cell_line", "compound_iname")
        temp2 <- temp1[,c(5,4,3,1,2)] 
        temp2
      })
      
      # Table of selected dataset ----
      output$table <- renderTable({
        outData()
      })
      
      # Downloadable csv of selected dataset ----
      output$downloadData <- downloadHandler(
        filename = function() {
          paste(input$in1_tt, "_", input$in2_cp, "_predictions.csv", sep = "")
        },
        content = function(file) {
          write.csv(outData(), file, row.names = FALSE)
        }
      )
    })
  })
}

# Create Shiny app ----
shinyApp(ui, server)