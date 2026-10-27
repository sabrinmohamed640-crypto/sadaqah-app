import 'package:flutter/material.dart';
import '../models/project_impact_model.dart';

class ProjectDummyData {
  ProjectDummyData._();

  static final List<ProjectImpactModel> allProjects = [
    // 1. Educational Waqf (waqf_edu) - Advanced Stages
    const ProjectImpactModel(
      projectId: 'waqf_edu',
      projectNameEn: 'Educational Waqf',
      projectNameAr: 'الوقف التعليمي',
      stages: [
        ProjectStage(
          titleEn: 'Endowment Fund Capitalization',
          titleAr: 'تأسيس رأس مال الوقف',
          dateEn: '15 Mar 2026',
          dateAr: '15 مارس 2026',
          descriptionEn: 'The initial endowment target of \$100k raised, and resources are locked in sustainable investments.',
          descriptionAr: 'تم جمع رأس المال المستهدف البالغ 100 ألف دولار واستثماره في أصول عقارية وقفية مدرة للدخل.',
          status: ProjectStageStatus.completed,
          icon: Icons.account_balance_rounded,
          proofs: [
            'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?q=80&w=400',
            'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=400',
          ],
        ),
        ProjectStage(
          titleEn: 'Scholar Selection & Enrollment',
          titleAr: 'فرز واختيار الطلاب المستحقين',
          dateEn: '25 Apr 2026',
          dateAr: '25 أبريل 2026',
          descriptionEn: 'Selection committee finalized the list of 150 underprivileged students for university scholarships.',
          descriptionAr: 'لجنة الاختيار والفرز تنتهي من تحديد 150 طالباً من الأسر المتعففة وتوزيع المنح الدراسية.',
          status: ProjectStageStatus.completed,
          icon: Icons.people_alt_rounded,
          proofs: [
            'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=400',
            'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?q=80&w=400',
          ],
        ),
        ProjectStage(
          titleEn: 'Tuition Disbursal & Study Cycle',
          titleAr: 'صرف الرسوم وبدء العام الدراسي',
          dateEn: '01 Jun 2026',
          dateAr: '01 يونيو 2026',
          descriptionEn: 'Disbursement of the first semester tuition fees directly to partner universities. Classes are ongoing.',
          descriptionAr: 'صرف رسوم الفصل الأول مباشرة للجامعات الشريكة. الطلاب في مقاعدهم الدراسية حالياً.',
          status: ProjectStageStatus.ongoing,
          icon: Icons.school_rounded,
        ),
      ],
    ),

    // 2. Water Well Waqf (waqf_water) - Early Stages
    const ProjectImpactModel(
      projectId: 'waqf_water',
      projectNameEn: 'Water Well Waqf',
      projectNameAr: 'وقف آبار المياه',
      stages: [
        ProjectStage(
          titleEn: 'Funding Goal Met',
          titleAr: 'اكتمال التمويل المستهدف',
          dateEn: '10 May 2026',
          dateAr: '10 مايو 2026',
          descriptionEn: 'Funding achieved. Procured drilling equipment and technical surveying for designated villages.',
          descriptionAr: 'تم اكتمال تمويل البئر وتعيين المقاول وتوفير معدات الحفر وإجراء المسح الجيولوجي.',
          status: ProjectStageStatus.completed,
          icon: Icons.monetization_on_rounded,
          proofs: [
            'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=400',
          ],
        ),
        ProjectStage(
          titleEn: 'Excavation & Pipe Installation',
          titleAr: 'بدء الحفر وتركيب المضخات',
          dateEn: '05 Jun 2026',
          dateAr: '05 يونيو 2026',
          descriptionEn: 'Drilling team deployed to the site. Excavation has commenced and piping is being laid down.',
          descriptionAr: 'فريق الحفر الهندسي يباشر العمل في الموقع. تم البدء في الحفر ووضع التمديدات.',
          status: ProjectStageStatus.ongoing,
          icon: Icons.plumbing_rounded,
          proofs: [
            'https://images.unsplash.com/photo-1541944743827-e04aa6427c33?q=80&w=400',
            'https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=400',
          ],
        ),
        ProjectStage(
          titleEn: 'Water Flow & Distribution',
          titleAr: 'تدفق المياه النظيفة والافتتاح',
          dateEn: '15 Jul 2026',
          dateAr: '15 يوليو 2026',
          descriptionEn: 'Installation of solar pump station, quality filtration tests, and inauguration of the well.',
          descriptionAr: 'تركيب منظومة الطاقة الشمسية وفلاتر تنقية المياه والافتتاح الرسمي للبئر للمستفيدين.',
          status: ProjectStageStatus.pending,
          icon: Icons.opacity_rounded,
        ),
      ],
    ),

    // 3. Quran Printing Waqf (waqf_quran) - Mid Stages
    const ProjectImpactModel(
      projectId: 'waqf_quran',
      projectNameEn: 'Quran Printing Waqf',
      projectNameAr: 'وقف طباعة المصحف',
      stages: [
        ProjectStage(
          titleEn: 'Copyrights & Paper Procurement',
          titleAr: 'حقوق النشر وتوفير الورق',
          dateEn: '20 Apr 2026',
          dateAr: '20 أبريل 2026',
          descriptionEn: 'Standard Quran layout verification completed by the scholarly committee. Premium paper stocks secured.',
          descriptionAr: 'اعتماد المراجعة والمصحف الشريف وتأمين مخزون من الورق الفاخر للطباعة.',
          status: ProjectStageStatus.completed,
          icon: Icons.menu_book_rounded,
          proofs: [
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=400',
          ],
        ),
        ProjectStage(
          titleEn: 'Press Printing & Leather Binding',
          titleAr: 'الطباعة وتجليد المصاحف',
          dateEn: '28 May 2026',
          dateAr: '28 مايو 2026',
          descriptionEn: 'Printing of 10,000 copies in progress at the specialized printing press. Binding phase active.',
          descriptionAr: 'جاري طباعة 10,000 نسخة من المصاحف الشريفة في المطبعة المخصصة وبدء التجليد.',
          status: ProjectStageStatus.ongoing,
          icon: Icons.print_rounded,
        ),
        ProjectStage(
          titleEn: 'Global Islamic Center Distribution',
          titleAr: 'التوزيع على المراكز الإسلامية',
          dateEn: '30 Jul 2026',
          dateAr: '30 يوليو 2026',
          descriptionEn: 'Logistics coordination to ship and distribute copies to remote villages and schools.',
          descriptionAr: 'شحن المصاحف وتوزيعها بالتنسيق مع الجمعيات الخيرية والمؤسسات التعليمية والمساجد.',
          status: ProjectStageStatus.pending,
          icon: Icons.local_shipping_rounded,
        ),
      ],
    ),

    // 4. Food Aid (opp_food) - Early/Funding Stage
    const ProjectImpactModel(
      projectId: 'opp_food',
      projectNameEn: 'Urgent Food Aid Campaign',
      projectNameAr: 'إغاثة عاجلة: سلات غذائية',
      stages: [
        ProjectStage(
          titleEn: 'Resource Allocation',
          titleAr: 'تخصيص الموارد وتوفير المؤن',
          dateEn: '12 Jun 2026',
          dateAr: '12 يونيو 2026',
          descriptionEn: 'Initial fundraising round complete. Sourcing dry foods and packaging kits in regional hubs.',
          descriptionAr: 'تجميع الحصيلة المبدئية والبدء في تعبئة السلال الغذائية من المراكز المحلية.',
          status: ProjectStageStatus.ongoing,
          icon: Icons.shopping_bag_rounded,
          proofs: [
            'https://images.unsplash.com/photo-1593113598332-cd288d649433?q=80&w=400',
            'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=400',
          ],
        ),
        ProjectStage(
          titleEn: 'Convoy Deployment',
          titleAr: 'تسيير قوافل الإغاثة',
          dateEn: '22 Jun 2026',
          dateAr: '22 يونيو 2026',
          descriptionEn: 'Logistics dispatch for relief trucks heading towards affected border camps.',
          descriptionAr: 'شحن الشاحنات وتجهيز القوافل اللوجستية للتوجه نحو مخيمات النزوح والمناطق المتضررة.',
          status: ProjectStageStatus.pending,
          icon: Icons.local_shipping_rounded,
        ),
        ProjectStage(
          titleEn: 'On-ground Distribution',
          titleAr: 'توزيع الحصص على المستفيدين',
          dateEn: '30 Jun 2026',
          dateAr: '30 يونيو 2026',
          descriptionEn: 'Door-to-door handovers to 1000 enrolled families verified by fingerprint receipt.',
          descriptionAr: 'تسليم السلال يداً بيد للعائلات المسجلة بقوائم المستفيدين في المناطق المستهدفة.',
          status: ProjectStageStatus.pending,
          icon: Icons.volunteer_activism_rounded,
        ),
      ],
    ),
  ];

  /// Resolves the specific dummy project details using name match.
  static ProjectImpactModel? getProjectByServiceName(String serviceName) {
    final nameLower = serviceName.toLowerCase();
    
    if (nameLower.contains('edu') || nameLower.contains('تعليم')) {
      return allProjects[0];
    } else if (nameLower.contains('water') || nameLower.contains('مياه') || nameLower.contains('آبار') || nameLower.contains('بئر')) {
      return allProjects[1];
    } else if (nameLower.contains('quran') || nameLower.contains('مصحف') || nameLower.contains('قرآن')) {
      return allProjects[2];
    } else if (nameLower.contains('food') || nameLower.contains('سلات') || nameLower.contains('غذاء') || nameLower.contains('إغاثة')) {
      return allProjects[3];
    }
    
    // Return null if it is a general donation (like quick pay) and not a specific project
    return null;
  }
}
