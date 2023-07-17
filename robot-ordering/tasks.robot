*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library    RPA.FileSystem
Library    RPA.Desktop
Library    RPA.PDF
Library    RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Download Order file
    ${orders}=    Get Orders
    Loop the Orders    ${orders}
    Zip Receipts
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    TRY
        Click Element    xpath://button[@class='btn btn-warning']
    EXCEPT    AS    ${error_message}
        Log    ${error_message}
    END

Download Order file
    Download
    ...    url=https://robotsparebinindustries.com/orders.csv
    ...    target_file=${CURDIR}
    ...    verify=${False}
    ...    overwrite=${False}

Get Orders
    ${orders}=    Read Table From CSV    ${CURDIR}/orders.csv
    RETURN    ${orders}

Loop the Orders    [Arguments]    ${orders}
    FOR    ${o}    IN    @{orders}
        Log    ${o}
        
        TRY
            Close the annoying modal
            Fill the Form    ${o}
        EXCEPT  AS    ${error_message}
            Log    ${error_message}
        END

    END

Fill the Form    [Arguments]    ${order}

    ${order number}=    Set Variable    ${order}[Order number]
    ${head}=    Set Variable    ${order}[Head]
    ${body}=    Set Variable    ${order}[Body]
    ${legs}=    Set Variable    ${order}[Legs]
    ${address}=    Set Variable    ${order}[Address]

    Select From List By Value    xpath://select[@name='head']    ${head}

    Select Radio Button    body    ${body}

    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${legs}

    Input Text    id=address    ${address}

    Click Element    preview
    ${screenshot}=    Take a screenshot of the robot    ${order_number}

    Click Element    order
    ${pdf}=    Store the receipt as a PDF file    ${order_number}

    Embed Robot Screenshot    ${pdf}    ${screenshot}    ${order number}

    Wait Until Element Is Visible    order-another
    Click Element    order-another

Store the receipt as a PDF file    [Arguments]    ${order_num}
    Print To Pdf    ${CURDIR}/output/receipts/${order_num}.pdf

    [Return]    ${CURDIR}/output/receipts/${order_num}.pdf

Take a screenshot of the robot    [Arguments]    ${order_num}
    ${png_dir}=    Set Variable    ${CURDIR}/output/robot_images
    Set Screenshot Directory    ${png_dir}
    Capture Element Screenshot    xpath://*[@id="robot-preview-image"]    ${order_num}.png
    ${png_file}=    Set Variable    ${png_dir}/${order_num}.png
    
    [Return]    ${png_file}

Embed Robot Screenshot    [Arguments]    ${pdf_file}    ${png_file}    ${order_num}
    Add Watermark Image To Pdf    image_path=${png_file}    output_path=${CURDIR}/output/robot_images/${order_num}_wpic.pdf    source_path=${pdf_file}

Zip Receipts
    Archive Folder With Zip    folder=${CURDIR}/output/robot_images    archive_name=${CURDIR}/output/robot_images.zip    recursive=True

Close the browser
    Close Browser