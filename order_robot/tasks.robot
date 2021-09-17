*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser
Library         RPA.Robocloud.Secrets
Library         RPA.PDF
Library         RPA.Tables
Library         Dialogs
Library         RPA.Excel.Files
Library         RPA.HTTP
Library         RPA.FileSystem
Library         RPA.Archive
Library         RPA.core.notebook



*** Keywords ***
Open the robot order website
    ${website}=    Get Secret    credentials
    Open Available Browser  ${website}[url]  
    Maximize Browser Window

*** Keywords ***
Get orders
    ${csv_file}=  Get Value From User  Please enter the csv file url  https://robotsparebinindustries.com/orders.csv
    Download  ${csv_file}  orders.csv
    Sleep  2 seconds
    ${data}=    Read Table From Csv    orders.csv    dialect=excel  header=True
    FOR     ${row}  IN  @{data}
        Log     ${row}
    END
    [Return]    ${data}

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element    //button[contains(text(),'OK')]
    Click Button    //button[contains(text(),'OK')]

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    ${head}=    Convert To Integer    ${row}[Head]
    ${body}=    Convert To Integer    ${row}[Body]
    ${legs}=    Convert To Integer    ${row}[Legs]
    ${address}=    Convert To String    ${row}[Address]
    Select From List By Value    //select[@name="head"]   ${head}
    Click Element   //input[@value="${Body}"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]    ${legs}
    Input Text  //input[@placeholder="Shipping address"]    ${address}

*** Keywords ***
Preview the robot
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep    2 seconds

*** Keywords ***
Submit the order
    Click Button    //button[@id="order"]
    Sleep    2 seconds
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END

*** Keywords ***
Export Pdf file and take screenshot
    [Arguments]    ${row}
    Sleep  2 seconds   
    ${receipt_data}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    Html To Pdf    ${receipt_data}    ${CURDIR}${/}output${/}receipt${/}${row}[Order number].pdf
    Screenshot     //div[@id="robot-preview-image"]   ${CURDIR}${/}output${/}screenshot${/}${row}[Order number].png
    Add Watermark Image To Pdf    ${CURDIR}${/}output${/}screenshot${/}${row}[Order number].png    ${CURDIR}${/}output${/}receipt${/}${row}[Order number].pdf   ${CURDIR}${/}output${/}receipt${/}${row}[Order number].pdf

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipt    receipt.zip    

*** Keywords ***
Go to order another robot
    Click Button    //button[@id='order-another']

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Export Pdf file and take screenshot    ${row}    
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]      Close Browser
