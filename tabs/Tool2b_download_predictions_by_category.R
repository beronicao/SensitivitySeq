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
      selectInput('in1_tt', 'Choose a tumor type of interest to query sensitivity predictions:', choices = NULL, multiple=TRUE, selectize=FALSE, selected = "All"),  
      
      fluidRow(
        column(10,
               h4("Select Compound"),
        )
      ),
      selectInput('in2_cp', 'Choose a drug of interest to filter sensitivity predictions by:', choices = NULL, multiple=FALSE, selectize=TRUE, selected = ""), 
      
      # Button
      downloadButton("downloadData", "Download")
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      fluidRow(
        column(
          DT::dataTableOutput("table"),
          width = 10)
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
  
  outTT = reactive({
    unique(predictions_list()$TCGA_model_src_name) 
  })
  
  observe({
    updateSelectInput(session, "in1_tt", 
                      choices = c("All", outTT())
    ) 
  })
  
  # Combine the selected variables into a new data frame
  observeEvent(eventExpr=input$in1_tt,ignoreInit = F, {
    selectedData <- reactive({
      if(c(input$in1_tt)=="All"){
        tbl1 <- predictions_list()
      } else {
        tbl1 <- predictions_list()[predictions_list()$TCGA_model_src_name==c(input$in1_tt),]
      }
      tbl1 
    })
    
    outVar = reactive({
      unique(selectedData()$pert_cmap_iname) 
    })
    
    observe({
      updateSelectizeInput(session, "in2_cp", 
                        choices = c("", outVar())
      ) 
    })

    observeEvent(eventExpr=input$in2_cp,ignoreInit = F, {
      outData_full <- reactive({
        if(c(input$in2_cp)==""){
          tbl <- selectedData()
        } else {
          tbl <- selectedData()[selectedData()$pert_cmap_iname==c(input$in2_cp),]
        }
        tbl
      })
      outData <- reactive({
        temp <- as.data.frame(outData_full())
        temp1 <- temp[,-c(1:3),drop=T]
        colnames(temp1)[c(3:5)]<- c("TCGA_tumor_type_code", "cell_line", "compound_iname")
        temp2 <- temp1[,c(5,4,3,1,2,7)] 
        temp2 <- temp2[order(as.numeric(temp2$prediction_estimate),decreasing = TRUE), ]
        temp2
      })
      
      # Table of selected dataset ----
      output$table <- DT::renderDataTable(escape = FALSE, 
                                          outData(),
        options = list(scrollX = TRUE), 
        rownames = FALSE 
        )
      
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