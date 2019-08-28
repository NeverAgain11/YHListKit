Pod::Spec.new do |s|
s.name             = "YHListKit-flow"
s.version          = "1.1.6"
s.summary          = "一个轻量级的数据驱动列表框架。A lightweight data-driven list framework for building fast and easy-to-use lists."
s.description      = <<-DESC
                    YHListKit 是一个基于 UICollectionView 的、轻量级的数据驱动列表框架，其核心思想在于通过 Adapter 模式将繁琐的 UICollectionView 相关代理方法转变成数据驱动的接口，更贴近人类的思维方式，让创建复杂 feeds 流列表跟写配置文件一样 easy。
                    DESC
s.homepage         = "https://github.com/ShannonChenCHN/YHListKit"
s.license          = 'MIT'
s.author           = {"ShannonChenCHN" => "shannonchenchn@foxmail.com"}
s.source           = {:git => "https://github.com/NeverAgain11/YHListKit", :tag => s.version}
s.requires_arc     = true
s.screenshot        = 'https://github.com/ShannonChenCHN/YHListKit/raw/master/src/preview.gif'

s.platform         = :ios, '9.0'
s.source_files     = 'YHListKit/**/*'
s.module_name      = "YHListKit"

end

