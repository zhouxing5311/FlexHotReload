Pod::Spec.new do |s|

  s.name         = "FlexHotReload"
  s.version      = "0.0.1"
  s.summary      = "can hot reload flex xml in debug mode"
  s.description  = <<-DESC
                    This tool depend on FlexLib, can add a hot reload capability for it in debug mode.
                   DESC
  s.homepage     = "https://github.com/zhouxing5311/FlexHotReload"
  s.license      = "MIT"
  s.author       = { "zhouxing" => "1098660224@qq.com" }
  s.ios.deployment_target = '9.0' 
  s.source       = { :git => "https://github.com/zhouxing5311/FlexHotReload.git", :tag => s.version.to_s}
  s.requires_arc = true

  s.source_files = 'Classes/**/*.{h,m,c,s}'
  s.dependency 'FlexLib'
end
