cask "sqlworkbenchj" do
  version "131"
  sha256 "b63e897988839cbd87114a50735c7f9b847941bdf5b5502ff212c1e1a12dc755"

  url "https://www.sql-workbench.eu/Workbench-Build#{version}.zip"
  name "SQL Workbench/J"
  desc "DBMS-independent SQL query tool"
  homepage "https://www.sql-workbench.eu/"

  livecheck do
    url "https://www.sql-workbench.eu/downloads.html"
    regex(/Workbench[._-]Build(\d+)\.zip/i)
  end

  # Prevent Homebrew from extracting the ZIP file automatically
  container type: :naked

  postflight do
    # Define the path to the app bundle
    app_path = "#{appdir}/SQLWorkbenchJ.app"

    # Create the necessary directories for the app bundle
    FileUtils.mkdir_p "#{app_path}/Contents/Java"
    FileUtils.mkdir_p "#{app_path}/Contents/MacOS"
    FileUtils.mkdir_p "#{app_path}/Contents/Resources"

    # Unpack the ZIP file contents into Contents/Java
    system_command "/usr/bin/unzip",
                   args: ["-qq", "#{staged_path}/Workbench-Build#{version}.zip", "-d", "#{app_path}/Contents/Java"],
                   print_stderr: false

    # Download the icon file and place it in Contents/Resources
    icon_url = "https://www.sql-workbench.eu/Workbench.icns"
    icon_destination = "#{app_path}/Contents/Resources/Workbench.icns"
    system_command "/usr/bin/curl",
                   args: ["-s", "-o", icon_destination, icon_url],
                   print_stderr: false

    # Create the Info.plist file in Contents/
    info_plist = <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
         "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleName</key>
          <string>SQLWorkbenchJ</string>
          <key>CFBundleDisplayName</key>
          <string>SQL Workbench/J</string>
          <key>CFBundleIdentifier</key>
          <string>sqlworkbench.app</string>
          <key>CFBundleVersion</key>
          <string>#{version}</string>
          <key>CFBundleExecutable</key>
          <string>SqlWorkbenchJLauncher</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>CFBundleIconFile</key>
          <string>Workbench.icns</string>
          <key>LSMinimumSystemVersion</key>
          <string>10.10.0</string>
          <key>NSHumanReadableCopyright</key>
          <string>Thomas Kellerer 2002-2024</string>
          <key>LSApplicationCategoryType</key>
          <string>public.app-category.developer-tools</string>
      </dict>
      </plist>
    EOS

    File.write("#{app_path}/Contents/Info.plist", info_plist)

    # Create the launcher script in Contents/MacOS/
    launcher_script = <<~EOS
      #!/bin/sh
      cd "$(dirname "$0")"/../Java
      exec java -Dapple.laf.useScreenMenuBar=true -Dapple.awt.showGrowBox=true -Xmx2048m -Xdock:name="SQL Workbench/J" -jar sqlworkbench.jar
    EOS

    File.write("#{app_path}/Contents/MacOS/SqlWorkbenchJLauncher", launcher_script)
    FileUtils.chmod "+x", "#{app_path}/Contents/MacOS/SqlWorkbenchJLauncher"
  end

  caveats do
    depends_on_java "11+"

    <<~EOS
      Due to macOS security restrictions, you may need to right-click on "SQLWorkbenchJ.app" in the /Applications folder and select "Open" to launch the application for the first time.
    EOS
  end
end

