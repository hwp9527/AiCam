classdef AiCam < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AiCamUIFigure           matlab.ui.Figure
        DevicesMenu             matlab.ui.container.Menu
        OptionsMenu             matlab.ui.container.Menu
        CaptureMenu             matlab.ui.container.Menu
        StartCaptureMenu        matlab.ui.container.Menu
        DevicesListBoxLabel     matlab.ui.control.Label
        DevicesListBox          matlab.ui.control.ListBox
        Button                  matlab.ui.control.Button
        ResolutionsButtonGroup  matlab.ui.container.ButtonGroup
        StartPreviewButton      matlab.ui.control.Button
        CaptureSavePanel        matlab.ui.container.Panel
        CaptureframesLabel      matlab.ui.control.Label
        CaptureframesEditField  matlab.ui.control.NumericEditField
        SaveFormatLabel         matlab.ui.control.Label
        SaveFormatDropDown      matlab.ui.control.DropDown
        SavePathLabel           matlab.ui.control.Label
        SavePathEditField       matlab.ui.control.EditField
        StartCaptureButton      matlab.ui.control.Button
        SelectPath              matlab.ui.control.Button
    end

    
    properties (Access = public)
        CamObj; % camera device obj
        DevName % device name
        SavePath % save capture image path
        Resolution % resolution for preview
        CaptureFrames % frames will be capture
        SaveFormat % save capture image formating
        ResAvalible % current camera avalibale resolutions
    end
    
    methods (Access = private)
        
        
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.CaptureFrames = 1;
            app.SaveFormat = 'tif';
            cl = webcamlist;
            n = size(cl);
            items = '';
            for i=1:n
                items = [items cl(i)];
                app.DevicesListBox.Items = items;
            end
        end

        % Menu selected function: DevicesMenu
        function DevicesMenuSelected(app, event)
            %% List connected webcams
            cam = webcamlist;
            n = size(cam);
            for i=1:n
                item = findobj(app.DevicesMenu, 'Tag', string(cam(i)));
                
                if isempty(item)
                    mitem = uimenu(app.DevicesMenu,'Text',string(cam(i)));
                    mitem.Tag = string(cam(i));
                    mitem.Separator = 'on';
                    %mitem.ForegroundColor = [1 0 0];
                    mitem.MenuSelectedFcn = createCallbackFcn(app, @DevSelected, true);
                end
            end
        end

        % Menu selected function: StartCaptureMenu
        function StartCaptureMenuSelected(app, event)
            savepath = 'C:\Users\hwp\Desktop';  %the folder
            nametemplate = 'image_%04d.tif';  %name pattern
            imnum = 0;        %starting image number
            for K = 1 : 1    %if you want to do this 50 times
                YourImage = snapshot(app.CamObj); %capture the image
                imnum = imnum + 1;
                thisfile = sprintf(nametemplate, imnum);  %create filename
                fullname = fullfile(savepath, thisfile);  %folder and all
                imwrite( YourImage, fullname);  %write the image there as tif
            end
        end

        % Value changed function: DevicesListBox
        function DevicesListBoxValueChanged(app, event)
            app.DevName = app.DevicesListBox.Value;
            
            app.CamObj = webcam(app.DevName);
            rs = app.CamObj.AvailableResolutions;
            [~, app.ResAvalible] = size(rs);
            left = 11;
            bottom = 344;
            width = app.ResolutionsButtonGroup.Position(3);%ButtonGroup width
            height = 20;
            
            for i=1:app.ResAvalible
                bt = uiradiobutton(app.ResolutionsButtonGroup);
                bt.Text = rs(i);
                bt.Position = [left bottom-25*i width height];
                bt.Value = true;
            end
        end

        % Button pushed function: StartPreviewButton
        function StartPreviewButtonPushed(app, event)
            if isempty(app.DevName)
                warndlg('Please select a camera!','Warning','modal');
                return
            end
            if isempty(app.Resolution)
                sl=app.ResolutionsButtonGroup.SelectedObject;
                class(sl)
                app.Resolution = sl.Text;
            end
            
            %% Setup Resolution
            app.CamObj.Resolution = char(app.Resolution);
            
            %% Setup preview window
            fig = figure('NumberTitle', 'off', 'MenuBar', 'none');
            fig.Name = app.DevName;
            ax = axes(fig);
            frame = snapshot(app.CamObj);
            frame = flip(frame, 3);
            im = image(ax, zeros(size(frame), 'uint8'));
            axis(ax, 'image');
            
            % Start preview
            preview(app.CamObj, im);
%             preview(app.CamObj);
%             image(frame);
            
            setappdata(fig, 'CamObj', app.CamObj);
            fig.CloseRequestFcn = @closePreviewWindow_Callback;
            %% Local functions
            function closePreviewWindow_Callback(obj, ~)
                app.CamObj = getappdata(obj, 'CamObj');
                closePreview(app.CamObj)
                delete(obj)
            end
            
        end

        % Value changed function: SavePathEditField
        function SavePathEditFieldValueChanged(app, event)
            value = app.SavePathEditField.Value;
            app.SavePath = value;
        end

        % Button pushed function: SelectPath
        function SelectPathButtonPushed(app, event)
            selected_dir = uigetdir();
            if selected_dir == 0
                warndlg('Please select an avaliable path!','Warning','modal');
                return
            end
            
            app.SavePath = selected_dir;
            app.SavePathEditField.Value = selected_dir;
        end

        % Selection changed function: ResolutionsButtonGroup
        function ResolutionsButtonGroupSelectionChanged(app, event)
            selectedButton = app.ResolutionsButtonGroup.SelectedObject;
            app.Resolution = selectedButton.Text;
            app.CamObj.Resolution = char(app.Resolution);
        end

        % Button pushed function: StartCaptureButton
        function StartCaptureButtonPushed(app, event)
            if isempty(app.DevName)
                warndlg('Please select a camera!','Warning','modal');
                return
            end
            if isempty(app.SavePath)
                warndlg('Please select a save path!','Warning','modal');
                return
            end
            app.StartCaptureButton.BackgroundColor = 'red';
            savepath = app.SavePath;  %the folder
            nametemplate = 'image_%02d.';  %name pattern
            nametemplate = [nametemplate app.SaveFormat];
            imnum = 0;        %starting image number
            for K = 1 : app.CaptureFrames
                frame = snapshot(app.CamObj); %capture the image
                imnum = imnum + 1;
                thisfile = sprintf(nametemplate, imnum);  %create filename
                fullname = fullfile(savepath, thisfile);  %folder and all
                imwrite( frame, fullname);  %write the image there as tif
            end
            app.StartCaptureButton.BackgroundColor = 'white';
        end

        % Value changed function: CaptureframesEditField
        function CaptureframesEditFieldValueChanged(app, event)
            value = app.CaptureframesEditField.Value;
            app.CaptureFrames = value;
        end

        % Value changed function: SaveFormatDropDown
        function SaveFormatDropDownValueChanged(app, event)
            value = app.SaveFormatDropDown.Value;
            app.SaveFormat = value;
        end

        % Close request function: AiCamUIFigure
        function AiCamUIFigureCloseRequest(app, event)
            clear app.CamObj;
            delete(app)           
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create AiCamUIFigure
            app.AiCamUIFigure = uifigure;
            app.AiCamUIFigure.Color = [1 1 1];
            app.AiCamUIFigure.Position = [100 100 640 480];
            app.AiCamUIFigure.Name = 'AiCam';
            app.AiCamUIFigure.Resize = 'off';
            app.AiCamUIFigure.CloseRequestFcn = createCallbackFcn(app, @AiCamUIFigureCloseRequest, true);

            % Create DevicesMenu
            app.DevicesMenu = uimenu(app.AiCamUIFigure);
            app.DevicesMenu.MenuSelectedFcn = createCallbackFcn(app, @DevicesMenuSelected, true);
            app.DevicesMenu.Text = 'Devices';

            % Create OptionsMenu
            app.OptionsMenu = uimenu(app.AiCamUIFigure);
            app.OptionsMenu.Text = 'Options';

            % Create CaptureMenu
            app.CaptureMenu = uimenu(app.AiCamUIFigure);
            app.CaptureMenu.Text = 'Capture';

            % Create StartCaptureMenu
            app.StartCaptureMenu = uimenu(app.CaptureMenu);
            app.StartCaptureMenu.MenuSelectedFcn = createCallbackFcn(app, @StartCaptureMenuSelected, true);
            app.StartCaptureMenu.Text = 'Start Capture';

            % Create DevicesListBoxLabel
            app.DevicesListBoxLabel = uilabel(app.AiCamUIFigure);
            app.DevicesListBoxLabel.HorizontalAlignment = 'center';
            app.DevicesListBoxLabel.VerticalAlignment = 'center';
            app.DevicesListBoxLabel.FontSize = 14;
            app.DevicesListBoxLabel.FontWeight = 'bold';
            app.DevicesListBoxLabel.FontAngle = 'italic';
            app.DevicesListBoxLabel.Position = [70 441 70 28];
            app.DevicesListBoxLabel.Text = 'Devices';

            % Create DevicesListBox
            app.DevicesListBox = uilistbox(app.AiCamUIFigure);
            app.DevicesListBox.Items = {};
            app.DevicesListBox.ValueChangedFcn = createCallbackFcn(app, @DevicesListBoxValueChanged, true);
            app.DevicesListBox.FontSize = 14;
            app.DevicesListBox.FontAngle = 'italic';
            app.DevicesListBox.Position = [10 71 191 370];
            app.DevicesListBox.Value = {};

            % Create Button
            app.Button = uibutton(app.AiCamUIFigure, 'push');
            app.Button.Position = [201 249 40 22];
            app.Button.Text = '?';

            % Create ResolutionsButtonGroup
            app.ResolutionsButtonGroup = uibuttongroup(app.AiCamUIFigure);
            app.ResolutionsButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ResolutionsButtonGroupSelectionChanged, true);
            app.ResolutionsButtonGroup.TitlePosition = 'centertop';
            app.ResolutionsButtonGroup.Title = 'Resolutions';
            app.ResolutionsButtonGroup.FontAngle = 'italic';
            app.ResolutionsButtonGroup.FontWeight = 'bold';
            app.ResolutionsButtonGroup.FontSize = 14;
            app.ResolutionsButtonGroup.Position = [241 71 150 390];

            % Create StartPreviewButton
            app.StartPreviewButton = uibutton(app.AiCamUIFigure, 'push');
            app.StartPreviewButton.ButtonPushedFcn = createCallbackFcn(app, @StartPreviewButtonPushed, true);
            app.StartPreviewButton.FontWeight = 'bold';
            app.StartPreviewButton.Position = [441 371 160 70];
            app.StartPreviewButton.Text = 'Start Preview';

            % Create CaptureSavePanel
            app.CaptureSavePanel = uipanel(app.AiCamUIFigure);
            app.CaptureSavePanel.TitlePosition = 'centertop';
            app.CaptureSavePanel.Title = 'Capture & Save';
            app.CaptureSavePanel.FontAngle = 'italic';
            app.CaptureSavePanel.FontWeight = 'bold';
            app.CaptureSavePanel.Position = [411 100 220 221];

            % Create CaptureframesLabel
            app.CaptureframesLabel = uilabel(app.CaptureSavePanel);
            app.CaptureframesLabel.FontWeight = 'bold';
            app.CaptureframesLabel.Position = [10 173 110 15];
            app.CaptureframesLabel.Text = 'Capture frames:';

            % Create CaptureframesEditField
            app.CaptureframesEditField = uieditfield(app.CaptureSavePanel, 'numeric');
            app.CaptureframesEditField.Limits = [0 Inf];
            app.CaptureframesEditField.ValueChangedFcn = createCallbackFcn(app, @CaptureframesEditFieldValueChanged, true);
            app.CaptureframesEditField.HorizontalAlignment = 'left';
            app.CaptureframesEditField.FontWeight = 'bold';
            app.CaptureframesEditField.Position = [130 169 80 22];
            app.CaptureframesEditField.Value = 1;

            % Create SaveFormatLabel
            app.SaveFormatLabel = uilabel(app.CaptureSavePanel);
            app.SaveFormatLabel.FontWeight = 'bold';
            app.SaveFormatLabel.Position = [11 133 110 15];
            app.SaveFormatLabel.Text = 'Save Format:';

            % Create SaveFormatDropDown
            app.SaveFormatDropDown = uidropdown(app.CaptureSavePanel);
            app.SaveFormatDropDown.Items = {'tif', 'png', 'bmp', 'jpg', 'gif'};
            app.SaveFormatDropDown.ValueChangedFcn = createCallbackFcn(app, @SaveFormatDropDownValueChanged, true);
            app.SaveFormatDropDown.FontWeight = 'bold';
            app.SaveFormatDropDown.Position = [131 129 80 22];
            app.SaveFormatDropDown.Value = 'tif';

            % Create SavePathLabel
            app.SavePathLabel = uilabel(app.CaptureSavePanel);
            app.SavePathLabel.HorizontalAlignment = 'right';
            app.SavePathLabel.FontWeight = 'bold';
            app.SavePathLabel.Position = [4 93 67 15];
            app.SavePathLabel.Text = 'Save Path:';

            % Create SavePathEditField
            app.SavePathEditField = uieditfield(app.CaptureSavePanel, 'text');
            app.SavePathEditField.ValueChangedFcn = createCallbackFcn(app, @SavePathEditFieldValueChanged, true);
            app.SavePathEditField.FontWeight = 'bold';
            app.SavePathEditField.Position = [74 89 120 22];

            % Create StartCaptureButton
            app.StartCaptureButton = uibutton(app.CaptureSavePanel, 'push');
            app.StartCaptureButton.ButtonPushedFcn = createCallbackFcn(app, @StartCaptureButtonPushed, true);
            app.StartCaptureButton.FontWeight = 'bold';
            app.StartCaptureButton.Position = [41 11 131 50];
            app.StartCaptureButton.Text = 'Start Capture';

            % Create SelectPath
            app.SelectPath = uibutton(app.CaptureSavePanel, 'push');
            app.SelectPath.ButtonPushedFcn = createCallbackFcn(app, @SelectPathButtonPushed, true);
            app.SelectPath.FontWeight = 'bold';
            app.SelectPath.Position = [191 86 28 25];
            app.SelectPath.Text = '...';
        end
    end

    methods (Access = public)

        % Construct app
        function app = AiCam

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AiCamUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AiCamUIFigure)
        end
    end
end