
require_relative "./lib/colcon_package.rb"
require_relative "./lib/colcon_import_package.rb"
require_relative "./lib/rosdep_import.rb"


if (!Autoproj.config.has_value_for?("ROS_DISTRO")) then
    # if ROS_DISTRO is set in the env, e.g. by sourcing the setup.bash, use that version
    # if not, assume lts as default and ask the user
    if (!ENV["ROS_DISTRO"].nil?) then
        puts "set from env"
        Autoproj.config.set("ROS_DISTRO", ENV["ROS_DISTRO"])
    else
        # Declare optione to ask for the desired ros version
        # options must have an implementation in the import function of ./lib/rosdep_import.rb
        # set default based on OS
        os_names, os_versions = Autoproj.workspace.operating_system
        if os_names.include?('ubuntu')
            if os_versions.include?('22.04')
                Autoproj.config.set("ROS_DISTRO", "humble")
            elsif os_versions.include?('24.04')
                Autoproj.config.set("ROS_DISTRO", "jazzy")
            end
        end        
    end
end

Autoproj.config.declare "ROS_DISTRO",
        "string",
        doc: ["Which ros version should be used to import package depenencies [humble, jazzy, rolling] ?", "\tyou can test other versions, osdeps files will be generated if name is valid"]

# get the selected ros version
ros_version = Autoproj.config.get("ROS_DISTRO")

# set file names
# get the package_set (this) folder to save files (nor where aup is called)
prefix = Autoproj.manifest.package_set("ros2").local_dir
ubuntu_osdeps = prefix+"/ubuntu.osdeps-"+ros_version
ros_osdeps = prefix+"/ros.osdeps-"+ros_version



# check if 
if (!Autoproj.config.has_value_for?("ROS_OSDEP_FORCE_UPDATE")) then
    Autoproj.config.set("ROS_OSDEP_FORCE_UPDATE", false)
end

Autoproj.config.declare "ROS_OSDEP_FORCE_UPDATE",
    "boolean",
    default: false,
    doc: ["Force update of the OS Dependency Definitions from rosdep?", "\tThis will import the most recent rosdep definitions once", "Please create a pull request if you did so and there were changes", "It is set to false automacically after update"]


force_import = false
if (Autoproj.config.get("ROS_OSDEP_FORCE_UPDATE") == true) then
    force_import = true
    Autoproj.config.set("ROS_OSDEP_FORCE_UPDATE", false)
end


# do import if selected version is not already imported, but if config is changed
if !File.exist?(ubuntu_osdeps) || !File.exist?(ros_osdeps) || force_import == true then
    Autoproj.message "Importing rosdep to #{ubuntu_osdeps} and #{ros_osdeps}" 
    importer = Ros2::RosdepImporter.new(ubuntu_osdeps, ros_osdeps)
    importer.import(ros_version)
    Autoproj.config.set("IMPORTED_ROS_OSDEPS", ros_version)
    # Autoproj.config.set("IMPORTED_ROS_TAGDATE", ros_tag_date)
end

# tell autoproj to load these files (a file without the suffix has to be present)
#Autoproj.message ("Load ros2 osdeps with the suffix #{ros_version}")
Autoproj.workspace.osdep_suffixes << ros_version


# ros_setup_bash = File.join(Autoproj.root_dir, '../install/setup.bash')
# if File.file?(ros_setup_bash)
#     Autoproj.env_source_file ros_setup_bash
# end


