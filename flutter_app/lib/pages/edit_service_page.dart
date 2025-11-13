import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_item.dart';
import '../providers/service_provider.dart';

/// 编辑/添加服务页面
class EditServicePage extends StatefulWidget {
  final ServiceItem? service;

  const EditServicePage({super.key, this.service});

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  
  IconData _selectedIcon = Icons.apps;
  Color _selectedColor = const Color(0xFF667eea);
  
  // 预设图标列表
  final List<IconData> _availableIcons = [
    Icons.apps,
    Icons.account_balance_wallet,
    Icons.language,
    Icons.attach_money,
    Icons.inventory,
    Icons.shopping_cart,
    Icons.business,
    Icons.home,
    Icons.work,
    Icons.school,
    Icons.local_hospital,
    Icons.restaurant,
    Icons.flight,
    Icons.hotel,
    Icons.local_shipping,
    Icons.directions_car,
  ];
  
  // 预设颜色列表
  final List<Color> _availableColors = [
    const Color(0xFF667eea),
    const Color(0xFF764ba2),
    const Color(0xFFf093fb),
    const Color(0xFF4facfe),
    const Color(0xFFfa709a),
    const Color(0xFFfee140),
    const Color(0xFF30cfd0),
    const Color(0xFFa8edea),
    const Color(0xFFff6e7f),
    const Color(0xFFbfe9ff),
    const Color(0xFF00f2fe),
    const Color(0xFF4facfe),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name);
    _urlController = TextEditingController(text: widget.service?.url);
    _descriptionController = TextEditingController(text: widget.service?.description);
    
    if (widget.service != null) {
      _selectedIcon = widget.service!.icon;
      _selectedColor = widget.service!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑服务' : '添加服务'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 预览卡片
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _selectedColor,
                        _selectedColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIcon,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameController.text.isEmpty ? '服务名称' : _nameController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 服务名称
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '服务名称',
                  hintText: '例如：记账',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务名称';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              
              const SizedBox(height: 16),
              
              // 服务URL
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: '服务URL',
                  hintText: '例如：http://192.168.0.197:3010',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务URL';
                  }
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return '请输入有效的URL（以http://或https://开头）';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 服务描述
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '服务描述（可选）',
                  hintText: '例如：家庭记账系统',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              
              // 选择图标
              const Text(
                '选择图标',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableIcons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _selectedColor : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 32,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // 选择颜色
              const Text(
                '选择颜色',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 32)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // 保存按钮
              ElevatedButton(
                onPressed: _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? '保存修改' : '添加服务',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveService() {
    if (_formKey.currentState!.validate()) {
      final serviceProvider = context.read<ServiceProvider>();
      
      final newService = ServiceItem(
        id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        url: _urlController.text,
        icon: _selectedIcon,
        color: _selectedColor,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );
      
      if (widget.service != null) {
        // 编辑现有服务
        serviceProvider.updateService(widget.service!.id, newService);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('服务已更新')),
        );
      } else {
        // 添加新服务
        serviceProvider.addService(newService);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('服务已添加')),
        );
      }
      
      Navigator.pop(context);
    }
  }
}
