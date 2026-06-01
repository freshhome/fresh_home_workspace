// import 'package:flutter/material.dart';
// import 'package:fresh_home/core/extensions/extension.dart';

// class ServiceCard extends StatelessWidget {
//   final String title;
//   final String? description;
//   final String? routeName;
//   final String? nameImage;
//   final Object? arguments;

//   const ServiceCard({
//     super.key,
//     required this.title,
//     this.description,
//     this.routeName,
//     this.nameImage,
//     this.arguments,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: routeName != null
//           ? () => context.pushNamed(routeName!,
//               arguments: arguments ?? "مجاش حاجه هنا")
//           : null,
//       borderRadius: BorderRadius.circular(15),
//       child: Container(
//         width: double.infinity,
//         margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
//         // padding: const EdgeInsets.symmetric(horizontal: 15),
//         height: 100,
//         decoration: BoxDecoration(
//           color: Colors.blue,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.grey.shade100, spreadRadius: 2, blurRadius: 4)
//           ],
//         ),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.arrow_back_sharp,
//               size: 40,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Text(
//                     title,
//                     textDirection: TextDirection.rtl,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   if (description != null) // عرض الوصف فقط لو كان موجودًا
//                     Text(
//                       description!,
//                       textDirection: TextDirection.rtl,

//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 2, // تجنب تجاوز النص لحجم العنصر
//                     ),
//                 ],
//               ),
//             ),
//             SizedBox(
//               width: 50,
//               child: Image.asset(
//                 nameImage ?? 'assets/images/Group.png',
//                 color: Colors.white,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
