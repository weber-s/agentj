<?php

namespace App\Controller;

use App\Controller\Traits\ControllerWBListTrait;
use App\Entity\User;
use App\Entity\Wblist;
use App\Form\UserPreferencesType;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

class AccountController extends AbstractController
{
    use ControllerWBListTrait;
    
    private $em;
    public function __construct(EntityManagerInterface $em) {
        $this->em=$em;
    }

  /**
   * @Route("/account", name="account")
   */
    public function index(Request $request)
    {

      /**@var  User  $user */
        $user = $this->getUser();
        $form = $this->createForm(UserPreferencesType::class, $this->getUser(), [
        'action' => $this->generateUrl('account'),
        ]);
        $form->handleRequest($request);
        if ($form->isSubmitted() && $form->isValid()) {
            $this->em->persist($this->getUser());
            $this->em->flush();
        }

        $wbDomain = $this->em->getRepository(Wblist::class)->getDefaultDomainWBList($user->getDomain());
        $domainDefaulWb = array_keys(array_filter($this->wBListDomainActions, function ($item) use ($wbDomain) {
            return $item == $wbDomain;
        }))[0];

        if ($user->getGroups() && $user->getGroups()->getWb()) {
            $wbGroup = $user->getGroups()->getWb();
            $groupDefaulWb = array_keys(array_filter($this->wBListUserActions, function ($item) use ($wbGroup) {
                return $item == $wbGroup;
            }))[0];
        } else {
            $groupDefaulWb = null;
        }


        return $this->render('account/index.html.twig', [
                'controller_name' => 'AccountController',
                'domainDefaulWb' => $domainDefaulWb,
                'groupDefaulWb' => $groupDefaulWb,
                'form' => $form->createView(),
        ]);
    }
}
